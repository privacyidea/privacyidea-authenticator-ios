//
//  PresenterDataAccess.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 15.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation

// Encapsulate the modification of data and updating of UI
extension Presenter: PresenterDelegate {
    
    func changeTokenLabel(_ label: String, index: Int) {
        model.getTokenAt(index).label = label
        datasetChanged()
    }
    
    func addToken(_ token: Token) {
        model.addToken(token)
        datasetChanged()
    }
    
    func addManuallyFinished(token: Token) {
        addToken(token)
    }
    
    //  Return the token at the index. Used to fill the cell.
    func getTokenForRow(index: Int) -> Token {
        return model.getTokenAt(index)
    }
    
    func getListCount() -> Int {
        return model.getListCount()
    }
    
    // Returns false if the token specified (by serial) in the request was not found
    func addPushAuthRequestToToken(_ req: PushAuthRequest) -> Bool {
        if let t = model.getTokenBySerial(req.serial) {
            t.pendingAuths.append(req)
            datasetChanged()
            U.log("Request added to token")
            return true
        } else {
            U.log("No token found for serial: \(req.serial)")
            return false
        }
    }
    
    func switchTokenPositions(src_index: Int, dest_index: Int) {
        let movedObject = model.removeTokenAt(src_index)
        model.insertTokenAt(token: movedObject, at: dest_index)
        datasetChanged()
    }
    
    // Store the tokenlist and update the UI
    func datasetChanged() {
        Storage.shared.saveTokens(list: model.getList())
        tableViewDelegate?.reloadCells()
    }
    
    func saveTokenlist() {
        Storage.shared.saveTokens(list: model.getList())
    }
    
    func removeTokenAt(index: Int) {
        let token = model.removeTokenAt(index)
        if token.type == Tokentype.PUSH {
            Storage.shared.removeKeysFor(token.serial)
            if !model.hasPushtokenLeft() {
                Storage.shared.deleteFirebaseConfig()
                //tableViewDelegate?.showMessageWithOKButton(title: "Firebase reset", message: "Restart App to reset Firebase")
            }
        }
        datasetChanged()
    }
    
    func removeToken(_ t: Token) {
        model.removeToken(t)
        datasetChanged()
    }
    
    // Checks all token of push type if there are expired authentication requests. If so the UI is reloaded and notifications are removed if possible.
    func checkExpiredAuthRequests() {
        if let expired = model.checkExpiredAuthRequests() {
            notificationManager?.removeNotifications(forIDs: expired)
            datasetChanged()
        }
    }
    
    // Checks all token of push type whose rollout is unfinished for their TTL. If it is expired a message is shown and the token is removed.
    func checkExpiredRollouts() {
        if let expiredTokens = model.checkExpiredRollouts() {
            for token in expiredTokens {
                model.removeToken(token)
                tableViewDelegate?.showMessageWithOKButton(title: NSLocalizedString("token_expired_dialog_title", comment: "token expired dialog title"),
                                                           message: "\(token.serial) " + NSLocalizedString("token_expired_dialog_text", comment: "... has expired and will be deleted (label will be prepended)"))
            }
            if expiredTokens.count > 0 {
                datasetChanged()
            }
        }
    }
    
}
