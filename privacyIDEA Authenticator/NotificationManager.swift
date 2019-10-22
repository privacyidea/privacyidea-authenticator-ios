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
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = false
        UIApplication.shared.registerForRemoteNotifications()
        U.log("Registered for PushNotifications")
        
        //register for special push responses
        let allowOption = UNNotificationAction(identifier: "ALLOW_ACTION", title: "Allow", options: [.authenticationRequired])
        let category = UNNotificationCategory(identifier: "PUSH_AUTHENTICATION", actions: [allowOption], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: [.hiddenPreviewsShowTitle, .hiddenPreviewsShowSubtitle])
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        U.log("FCM Message received \(remoteMessage.appData)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        U.log(fcmToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        U.log(response)
        let userInfo = response.notification.request.content.userInfo
        U.log(userInfo)
        if let serial = userInfo["serial"] as? String,
            let signature = userInfo["signature"] as? String,
            let nonce = userInfo["nonce"] as? String,
            let sslVerifyStr = userInfo["sslverify"] as? String,
            let url = userInfo["url"] as? String,
            let title = userInfo["title"] as? String,
            let question = userInfo["question"] as? String {
            
            guard let token = presenter.model.getTokenBySerial(serial) else {
                U.log("No token found to start authentication for (serial: \(serial))")
                return
            }
            
            let id = UUID().uuidString
            var sslVerify = true
            if let sslVerifyInt = Int(sslVerifyStr) {
                sslVerify = Bool(sslVerifyInt)
            }
            // TTL of a PushRequest is 2min ? // MARK: PUSH TTL
            let ttl: Date = Date().addingTimeInterval(Double(2) * 60.0)
            let pushauthreq = PushAuthRequest(id: id, url: url, nonce: nonce, signature: signature, serial: serial, title: title, question: question, sslVerify: sslVerify, ttl: ttl)
            
            _ = self.presenter.addPushAuthRequestToToken(pushauthreq)
            
            //send the confirmation if the user tapped allow from the notification
            if response.actionIdentifier == "ALLOW_ACTION" {
                token.setState(State.AUTHENTICATING)
                self.presenter.tableViewDelegate?.reloadCells()
                //start a background task to ensure the push can be sent
                self.presenter.registerBackgroundTask()
                self.presenter.pushAuthentication(forToken: token)
            }
        }
        
        completionHandler()
    }
    
    func removeNotifications(forIDs: [String]) {
        //U.log("Removing notifications for: \(forIDs)")
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: forIDs)
    }
    
    func buildNotification(forRequest: PushAuthRequest) {
        let content = UNMutableNotificationContent()
        content.title = forRequest.title
        content.body = forRequest.question
        content.categoryIdentifier = "PUSH_AUTHENTICATION"
        content.userInfo = ["serial" : forRequest.serial,
                            "signature" : forRequest.signature,
                            "nonce" : forRequest.nonce,
                            "sslverify" : forRequest.sslVerify,
                            "ttl" : forRequest.ttl,
                            "url" : forRequest.url,
                            "title" : forRequest.title,
                            "question" : forRequest.question]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        // Use the id of the push auth request for the notification, so it can be removed when the request expires
        //U.log("New notification with ID: \(forRequest.id)")
        let request = UNNotificationRequest(identifier: forRequest.id, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                U.log("Error while adding notification: \(error!.localizedDescription)")
            }
        }
    }
}
