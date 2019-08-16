//
//  PresenterEndpointCallback.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 17.06.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation

extension Presenter: EndpointCallback {
    func errorOccured(_ token: Token) {
        U.log("errorOccured: \(String(describing: token.getLastestError()?.localizedDescription))")
        switch token.getState() {
        case State.ENROLLING: token.setState(State.UNFINISHED)
        default: token.setState(State.FINISHED)
        }
        
        datasetChanged()
    }
    
    func responseReceived(response: [String : Any], _ token: Token) {
        // Get the Detail field from the response and JSON it
        guard let idxDetail = response.index(forKey: "detail") else {
            // U.log("No Detail in response")
            // Might be authentication response
            processAuthenticationResponse(response, token: token)
            return
        }
        
        if let detail = response[idxDetail].value as? [String: Any] {
            // Get the PublicKey and serial from the response
            guard let idxPubKey = detail.index(forKey: "public_key") else {
                U.log("no public key in response")
                return
            }
            guard let idxSerial = detail.index(forKey: "serial") else {
                U.log("no serial in response")
                return
            }
            
            let publicKey: String = detail[idxPubKey].value as! String
            let serial: String = detail[idxSerial].value as! String
            
            guard let token = model.getTokenBySerial(serial) else {
                U.log("No token found for serial: \(serial)")
                return
            }
            if !(Storage.shared.savePIPublicKey(serial: serial, publicKeyStr: publicKey)) {
                U.log("Failed to save piPublicKey, wrong format?")
                return
            }
            
            // Rollout finished - set token to rolled out
            U.log("Push Rollout successful for: \(serial)")
            token.setState(State.FINISHED)
            datasetChanged()
        }
    }
    
    func processAuthenticationResponse(_ response: [String : Any], token: Token) {
        // Get the result field
        guard let idxResult = response.index(forKey: "result") else {
            U.log("no result field in reponse")
            return
        }
        
        if let result = response[idxResult].value as? [String : Any] {
            guard let idxValue = result.index(forKey: "value") else {
                U.log("no value field in result")
                return
            }
            
            let success: Bool = result[idxValue].value as! Bool
            U.log("success: \(success)")
            
            guard let idxNonce = response.index(forKey: "nonce") else {
                U.log("nonce not found in response")
                return
            }
            let nonce = response[idxNonce].value as! String
            authenticationFinished(token: token, nonce: nonce, success)
        }
    }
    
    func authenticationFinished(token: Token, nonce: String, _ success: Bool) {
        // Reset state and error regardless of success
        token.setState(State.FINISHED)
        token.setLastestError(nil)
        
        for p in token.pendingAuths {
            if p.nonce == nonce {
                if success {
                    token.pendingAuths = token.pendingAuths.filter( { $0 !== p } )
                    tokenlistDelegate?.showToastMessage(text: "Authentication successful!")
                    self.datasetChanged()
                } else {
                    tokenlistDelegate?.showToastMessage(text: "Authentication failed!")
                }
                // TODO remove failed authentication? it is probably impossible to get it right if it fails (without an error from "outside")
            }
        }
    }
}
