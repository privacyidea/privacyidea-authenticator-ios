//
//  Presenter.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 09.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import SwiftOTP
import CommonCrypto
import Security
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications

class Presenter {
    
    var model: Model
    var tokenlistDelegate: TokenlistDelegate?
    var notificationManager: NotificationManager?
    
    init(tokenlistDelegate: TokenlistDelegate) {
        self.tokenlistDelegate = tokenlistDelegate
        self.model = Model(token: Storage.shared.loadTokens())
    }
    
    func startup() {
        // MARK: STARTUP
        if model.hasPushtokenLeft() {
            U.log("Pushtoken present on startup")
            loadAndInitFirebase()
        } else {
            U.log("no pushtoken present on startup")
            Storage.shared.deleteFirebaseConfig()
        }
        
        notificationManager = NotificationManager(self)
        notificationManager?.registerForPushNotifications()
        
        let expiredTokens = model.checkForExpiredRollouts()
        if expiredTokens != nil {
            for t in expiredTokens! {
                tokenExpired(t)
            }
        }
    }
    
    func timerProgress(progress: Int) {
        let seconds = progress
        // Reload the cells only around the TOTP switching times
        // Reloading the cell closes the menu opened by swiping
        if (seconds < 31 && seconds > 29 || seconds > 58){
            model.refreshTOTP()
            tokenlistDelegate?.reloadCells()
        }
        // Also check for expired PushAuthenticationRequests
        let expired = model.checkForExpiredAuthRequests()
        if expired != nil {
            // Try to remove the notification if there is
            notificationManager?.removeNotifications(forIDs: expired!)
            tokenlistDelegate?.reloadCells()
        }
        
        // Update progressbars
        for i in 0..<model.getListCount() {
            let indexPath = IndexPath(row: i, section: 0)
            tokenlistDelegate?.updateProgressbar(indexPath: indexPath, progress: seconds)
        }
    }
    
    func tokenExpired(_ t: Token) {
        removeToken(t)
        tokenlistDelegate?.showMessageWithOKButton(title: "Token expired!", message: "\(t.serial) has expired and will be deleted.")
    }
}

// MARK: CELL BUTTON ONCLICK
extension Presenter: PresenterCellDelegate {
    @objc func confirmedPushAuthentication(_ sender: UIButton) {
        U.log("Confirmed push at: \(sender.tag)")
        let t = model.getTokenAt(sender.tag)
        
        if t.type != Tokentype.PUSH || t.pendingAuths.count < 1 {
            U.log("PushAuth: token is not PUSH type or AuthReq is non existent, count: \(t.pendingAuths.count)")
            return
        }
        
        t.setState(State.AUTHENTICATING)
        tokenlistDelegate?.reloadCells()
        //sender.isEnabled = false
        pushAuthentication(forToken: t)
    }
    
    @objc func retryRollout(_ sender: UIButton) {
        let token = model.getTokenAt(sender.tag)
        if token.type != Tokentype.PUSH {
            U.log("PushRollout retry: token is not PUSH type")
            return
        }
        initPushRollout(token)
    }
}
