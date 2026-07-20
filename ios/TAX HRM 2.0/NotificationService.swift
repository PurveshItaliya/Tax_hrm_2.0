//
//  NotificationService.swift
//  TAX HRM 2.0
//
//  Created by Sunil Rajai on 18/07/26.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Find image URL string from FCM or APNs custom payload keys
        var imageURLString: String? = nil
        
        if let fcmOptions = request.content.userInfo["fcm_options"] as? [String: Any],
           let image = fcmOptions["image"] as? String {
            imageURLString = image
        } else if let image = request.content.userInfo["gcm.notification.image"] as? String {
            imageURLString = image
        } else if let image = request.content.userInfo["image"] as? String {
            imageURLString = image
        } else if let image = request.content.userInfo["imageUrl"] as? String {
            imageURLString = image
        } else if let image = request.content.userInfo["attachment-url"] as? String {
            imageURLString = image
        }
        
        guard let urlString = imageURLString, let imageURL = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: imageURL) { [weak self] (tempURL, response, error) in
            guard let self = self, let tempURL = tempURL, error == nil else {
                contentHandler(bestAttemptContent)
                return
            }
            
            let fileManager = FileManager.default
            let fileExtension = imageURL.pathExtension.isEmpty ? "jpg" : imageURL.pathExtension
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
                
            do {
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                let attachment = try UNNotificationAttachment(identifier: "image", url: destinationURL, options: nil)
                bestAttemptContent.attachments = [attachment]
            } catch {
                print("Error creating notification attachment: \(error)")
            }
            
            contentHandler(bestAttemptContent)
        }
        
        task.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
