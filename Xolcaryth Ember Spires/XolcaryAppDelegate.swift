import UIKit
import CoreText
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import UserNotifications

class XolcaryAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = XolcaryAppsFlyerModel.sharedInstance
        FirebaseApp.configure()
        
        let initialLaunchKey = "APP_INITIAL_LAUNCH_FLAG"
        if UserDefaults.standard.object(forKey: initialLaunchKey) == nil {
            UserDefaults.standard.set(true, forKey: initialLaunchKey)
        } else {
            UserDefaults.standard.set(false, forKey: initialLaunchKey)
        }
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            UserDefaults.standard.set(remoteNotification, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let token = token {
                UserDefaults.standard.set(token, forKey: "FIREBASE_MESSAGING_TOKEN")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let _ = userInfo["url"] as? String {
            UserDefaults.standard.set(userInfo, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
        }
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity)
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомление даже когда приложение в foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationUserInfo = response.notification.request.content.userInfo
        if let urlString = notificationUserInfo["url"] as? String {
            // Очищаем предыдущие данные push-уведомлений перед сохранением новых
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.removeObject(forKey: "PUSH_LAUNCH_FLAG")
            UserDefaults.standard.set(notificationUserInfo, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
            DispatchQueue.main.async {
                MafiaLoadingModel.sharedController.terminateAllActiveTimers()
                MafiaLoadingModel.sharedController.presentWebView(url: urlString)
            }
        }
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if UserDefaults.standard.bool(forKey: "APP_INITIAL_LAUNCH_FLAG") {
            return
        }
        guard let token = fcmToken else { return }
        UserDefaults.standard.set(token, forKey: "FIREBASE_MESSAGING_TOKEN")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.allowedOrientations
    }
}
