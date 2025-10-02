import FirebaseMessaging
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  var notificationContentHandler: ((UNNotificationContent) -> Void)?
  var processedNotificationContent: UNMutableNotificationContent?

  override func didReceive(_ request: UNNotificationRequest,
                           withContentHandler contentHandler: @escaping (UNNotificationContent)
                             -> Void) {
    self.notificationContentHandler = contentHandler
    processedNotificationContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let processedNotificationContent {
      processedNotificationContent.title = "\(processedNotificationContent.title)"

      Messaging.serviceExtension()
        .exportDeliveryMetricsToBigQuery(withMessageInfo: request.content.userInfo)

      Messaging.serviceExtension()
        .populateNotificationContent(processedNotificationContent, withContentHandler: contentHandler)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let notificationContentHandler, let processedNotificationContent {
      notificationContentHandler(processedNotificationContent)
    }
  }
}
