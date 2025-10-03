import UIKit
import CoreText
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = AppsSetModel.sharedInstance
        FirebaseApp.configure()
        
        let firstRunKey = "APPLICATION_FIRST_RUN_STATUS"
        if UserDefaults.standard.object(forKey: firstRunKey) == nil {
            UserDefaults.standard.set(true, forKey: firstRunKey)
        } else {
            UserDefaults.standard.set(false, forKey: firstRunKey)
        }
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        if let pushPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            UserDefaults.standard.set(pushPayload, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { fcmToken, error in
            if let fcmToken = fcmToken {
                UserDefaults.standard.set(fcmToken, forKey: "FCM_DEVICE_TOKEN")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notificationData: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let _ = notificationData["url"] as? String {
            UserDefaults.standard.set(notificationData, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
        }
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity)
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let pushData = response.notification.request.content.userInfo
        if let urlString = pushData["url"] as? String {
            UserDefaults.standard.removeObject(forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.removeObject(forKey: "PUSH_LAUNCH_FLAG")
            UserDefaults.standard.set(pushData, forKey: "PENDING_NOTIFICATION_DATA")
            UserDefaults.standard.set(true, forKey: "PUSH_LAUNCH_FLAG")
            DispatchQueue.main.async {
                StartingModel.sharedController.stopAllRunningTimers()
                StartingModel.sharedController.displayWebInterface(url: urlString)
            }
        }
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken registrationToken: String?) {
        if UserDefaults.standard.bool(forKey: "APPLICATION_FIRST_RUN_STATUS") {
            return
        }
        guard let token = registrationToken else { return }
        UserDefaults.standard.set(token, forKey: "FCM_DEVICE_TOKEN")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.supportedOrientations
    }
}
