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
    var tableViewDelegate: TokenlistDelegate?
    var notificationManager: NotificationManager?
    
    init(tokenlistDelegate: TokenlistDelegate) {
        self.tableViewDelegate = tokenlistDelegate
        self.model = Model(token: Storage.shared.loadTokens())
    }
    
    func startup() {
        // MARK: STARTUP
        
        model.hasPushtokenLeft() ? loadAndInitFirebase() : Storage.shared.deleteFirebaseConfig()
        
        notificationManager = NotificationManager(self)
        notificationManager?.registerForPushNotifications()
        
        checkExpiredRollouts()
        checkExpiredAuthRequests()
    }
    
    func timerProgress(seconds: Int) {
        // Reload the cells only around the TOTP switching times
        // Reloading the cell closes the menu opened by swiping
        if (seconds < 31 && seconds > 29 || seconds > 58) {
            model.refreshTOTP()
            tableViewDelegate?.reloadCells()
        }
      
        checkExpiredAuthRequests()
        checkExpiredRollouts()
        
        // Update progressbars
        for i in 0..<getListCount() {
            let indexPath = IndexPath(row: i, section: 0)
            tableViewDelegate?.updateProgressbar(indexPath: indexPath, progress: seconds)
        }
    }
}

// MARK: CELL BUTTON ONCLICKS
extension Presenter: PresenterCellDelegate {
    @objc func confirmedPushAuthentication(_ sender: UIButton) {
        U.log("Confirmed push at: \(sender.tag)")
        let t = model.getTokenAt(sender.tag)
        
        if t.type != Tokentype.PUSH || t.pendingAuths.count < 1 {
            U.log("PushAuth: token is not PUSH type or PAR is not existing")
            return
        }
        
        t.setState(State.AUTHENTICATING)
        tableViewDelegate?.reloadCells()
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
    
    @objc func dismissPushAuthentication(_ sender: UIButton) {
        let t = model.getTokenAt(sender.tag)
        
        if t.type != Tokentype.PUSH || t.pendingAuths.count < 1 {
            U.log("PushAuth: token is not PUSH type or PAR is not existing")
            return
        }
        
        t.pendingAuths.remove(at: 0)
        t.setLastestError(nil)
        datasetChanged()
    }
    
    @objc func increaseHOTP(_ sender: UIButton) {
        model.increaseHOTP(index: sender.tag)
        sender.isEnabled = false
        datasetChanged()
        // Deactivate the button and reactivate it 2s later
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            sender.isEnabled = true
        }
    }
}
