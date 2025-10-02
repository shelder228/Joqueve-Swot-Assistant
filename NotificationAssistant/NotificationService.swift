import UserNotifications
import FirebaseMessaging

class NotificationService: UNNotificationServiceExtension {
    
    private var completionHandler: ((UNNotificationContent) -> Void)?
    private var modifiedContent: UNMutableNotificationContent?
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler handler: @escaping (UNNotificationContent) -> Void
    ) {
        self.completionHandler = handler
        self.modifiedContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        guard let content = modifiedContent else {
            handler(request.content)
            return
        }
        
        content.title = "\(content.title)"
        
        Messaging.serviceExtension()
            .exportDeliveryMetricsToBigQuery(withMessageInfo: request.content.userInfo)
        
        Messaging.serviceExtension()
            .populateNotificationContent(content, withContentHandler: handler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let handler = completionHandler, let content = modifiedContent {
            handler(content)
        }
    }
}
