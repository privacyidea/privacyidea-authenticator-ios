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
    //private typealias U = Utilities
    
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
    
    /**
     Return the token at the index used to fill the cell.
     */
    func getTokenForRow(index: Int) -> Token {
        return model.getTokenAt(index)
    }
    
    func getListCount() -> Int {
        return model.getListCount()
    }
    
    func addPushAuthRequestToToken(_ req: PushAuthRequest) {
        if let t = model.getTokenBySerial(req.serial) {
            t.pendingAuths.append(req)
            datasetChanged()
            U.log("Request added to token")
        } else {
            U.log("No token found for serial: \(req.serial)")
            U.log("no token found for serial \(req.serial)")
        }
    }
    
    func switchTokenPositions(src_index: Int, dest_index: Int) {
        let movedObject = model.removeTokenAt(src_index)
        model.insertTokenAt(token: movedObject, at: dest_index)
        datasetChanged()
    }
    /** Store the tokenlist and update the UI */
    func datasetChanged() {
        Storage.shared.saveTokens(list: model.getList())
        tokenlistDelegate?.reloadCells()
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
                tokenlistDelegate?.showMessageWithOKButton(title: "Firebase reset", message: "Restart App to reset Firebase")
            }
        }
        datasetChanged()
    }
    
    func nextButtonTapped(index: Int) {
        model.increaseHOTP(index: index)
        datasetChanged()
    }
    
    func removeToken(_ t: Token) {
        model.removeToken(t)
        datasetChanged()
    }
}
