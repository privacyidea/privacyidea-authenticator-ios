//
//  NotificationManager.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 30.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

class NotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    var presenter: Presenter
    
    init(_ presenter: Presenter) {
        self.presenter = presenter
    }
    
    func registerForPushNotifications() {
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                // For iOS 10 display notification (sent via APNS)
                UNUserNotificationCenter.current().delegate = self
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
                // For iOS 10 data message (sent via FCM)
                
            } else {
                let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
            }
            Messaging.messaging().delegate = self
            UIApplication.shared.registerForRemoteNotifications()
            U.log("Registered for PushNotifications")
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        U.log("FCM Message received \(remoteMessage.appData)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        U.log(fcmToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        U.log(response)
        
        // Allow pressed?
        //presenter.addPushAuthRequestToToken(<#T##req: PushAuthRequest##PushAuthRequest#>)
        //presenter.pushAuthenticationForToken(T##t: Token##Token)
        
        let userInfo = response.notification.request.content.userInfo
        let serial = userInfo["SERIAL"] as! String
        /*let signature = userInfo["SIGNATURE"] as! String
         let nonce = userInfo["NONCE"] as! String
         let sslVerify = userInfo["SSLVERIFY"] as! String
         let url = userInfo["URL"] as! String
         let title = userInfo["TITLE"] as! String
         let question = userInfo["QUESTION"] as! String
         
         // TTL of a PushRequest is 2min ? // MARK: PUSH TTL
         let ttl: Date = Date().addingTimeInterval(Double(2) * 60.0)
         let req = PushAuthRequest(url: url, nonce: nonce, signature: signature, serial: serial, title: title, question: question, sslVerify: <#T##Bool#>, ttl: Date)
         */
        
        guard let token = presenter.model.getTokenBySerial(serial) else {
            U.log("No token found to start authentication for (serial: \(serial))")
            return
        }
        
        if response.actionIdentifier == "ALLOW_ACTION" {
            self.presenter.pushAuthentication(forToken: token)
        }
        
        completionHandler()
    }
    
    func removeNotifications(forIDs: [String]) {
        U.log("removing notifications for:")
        U.log(forIDs)
        let center = UNUserNotificationCenter.current()
        
        center.removeDeliveredNotifications(withIdentifiers: forIDs)
        center.removePendingNotificationRequests(withIdentifiers: forIDs)
    }
    
    func buildNotification(forRequest: PushAuthRequest) {
        //let allowOption = UNNotificationAction(identifier: "ALLOW_ACTION", title: "Allow", options: UNNotificationActionOptions(rawValue: 0))
        let category = UNNotificationCategory(identifier: "PUSH_AUTHENTICATION", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .hiddenPreviewsShowTitle)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])
        let content = UNMutableNotificationContent()
        content.title = forRequest.title
        content.body = forRequest.question
        content.categoryIdentifier = "PUSH_AUTHENTICATION"
        content.userInfo = ["SERIAL" : forRequest.serial,
                            "SIGNATURE" : forRequest.signature,
                            "NONCE" : forRequest.nonce,
                            "SSLVERIFY" : forRequest.sslVerify,
                            "TTL" : forRequest.ttl,
                            "URL" : forRequest.url,
                            "TITLE" : forRequest.title,
                            "QUESTION" : forRequest.question]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        // Use the id of the push auth request for the notification, so it can be removed when the request expires
        let request = UNNotificationRequest(identifier: forRequest.id, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if error != nil {
                U.log("Error while adding notification: \(error!.localizedDescription)")
            }
        }
    }
}
