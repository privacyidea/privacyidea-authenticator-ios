//
//  PresenterPushFIR.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 15.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMessaging
import FirebaseInstanceID

extension Presenter {
    // MARK: - PUSH
    func firebaseInit(_ config: FirebaseConfig) {
        U.log("Initializing Firebase...")
        // check if Firebase is already initalized
        if FirebaseApp.allApps == nil || FirebaseApp.allApps!.isEmpty {
            let options = FirebaseOptions(googleAppID: config.appID, gcmSenderID: config.projNumber)
            options.apiKey = config.api_key
            options.databaseURL = "https://" + config.projID + ".firebase.io.com"
            options.storageBucket = config.projID + ".appspot.com"
            options.projectID = config.projID
            
            do {
                try ObjCException.catch {
                    FirebaseApp.configure(options: options)
                }
            } catch {
                tableViewDelegate?.popViewController()
                tableViewDelegate?.showMessageWithOKButton(title: NSLocalizedString("firebase_init_error", comment: "") , message: NSLocalizedString("firebase_init_error_message", comment: ""))
                Storage.shared.deleteFirebaseConfig()
                U.log("Firebase initialization Error: \(error.localizedDescription)")
            }
            U.log("Firebase initialized")
        } else {
            U.log("Firebase already initalized for: " + (FirebaseApp.allApps?.description ?? ("default value" as String)))
        }
    }
    
    // Save the config only if there is none saved yet
    func saveFirebaseConfig(_ config: FirebaseConfig) {
        if Storage.shared.loadFirebaseConfig() == nil {
            Storage.shared.saveFirebaseConfig(config)
        }
    }
    
    // Try to load the FirebaseConfig - if there is one, start the init
    func loadAndInitFirebase() {
        if let tmp = Storage.shared.loadFirebaseConfig() {
            firebaseInit(tmp)
        }
    }
    
    func initPushRollout(_ token: Token) {
        // Verify the tokens ttl
        if token.expirationDate == nil {
            token.expirationDate = Date().addingTimeInterval(Double(2) * 60.0)
            U.log("push rollout expiration date nil, setting it to now +2 minutes")
        }
        
        if token.expirationDate! < Date() {
            U.log("TTL expired:")
            //U.log(token.expirationDate!)
            self.removeToken(token)
            tableViewDelegate?.showMessageWithOKButton(title: NSLocalizedString("token_expired_dialog_title", comment: "token expired dialog title"),
                                                       message: "\(token.serial) " + NSLocalizedString("token_expired_dialog_text", comment: "... has expired and will be deleted (label will be prepended)"))
            return
        }
        
        U.log("Preparing for Push rollout:")
        token.setState(State.ENROLLING)
        token.setLastestError(nil)// reset lastestError on new action
        tableViewDelegate?.reloadCells()
        U.log("Getting Firebase Token from InstanceID ...")
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("unable_to_get_firebase_token", comment: ""))
                U.log("Error getting Firebase Token: \(error)")
            } else if let result = result {
                // U.log("Firebase Token: \(result.token)")
                self.pushRollout(token, result.token)
            }
        }
    }
    
    /**
     BACKGROUND THREAD
     */
    private func pushRollout(_ token: Token, _ fbtoken: String) {
        if token.type != Tokentype.PUSH { return }
        DispatchQueue.global(qos: .background).async {
            U.log("starting push rollout...")
            
            // 1. Generate a new keypair (RSA 4096bit), the private key is stored with the serial as alias
            guard let rawPublicKey = Crypto.shared.generateKeypair(token.serial) else  {
                self.tableViewDelegate?.showMessageWithOKButton(title: NSLocalizedString("rsa_key_generation_fail_title", comment: ""),
                                                                message: NSLocalizedString("rsa_key_generation_fail_message", comment: ""))
                return
            }
            
            // Add the PublicKeyInfo manually here
            let fullKey = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A" + Utilities().b64Tob64URLSafe(rawPublicKey)
            
            // Verify parameters are present, if not token will be deleted as it is useless
            guard let enrollment_credential = token.enrollment_credential else {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("push_enrollment_parameters_missing", comment: ""))
                U.log("Enrollment credential not present")
                self.removeToken(token)
                return
            }
            guard let enrollment_url = token.enrollment_url else {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("push_enrollment_parameters_missing", comment: ""))
                U.log("Enrollment url not present")
                self.removeToken(token)
                return
            }
            
            // Put parameters in dict
            let parameters: [String : String] =
                [ "enrollment_credential": enrollment_credential,
                  "serial": token.serial,
                  "fbtoken": fbtoken,
                  "pubkey": fullKey ]
            
            Endpoint(url: enrollment_url, data: parameters, sslVerify: (token.sslVerify ?? true), token: token, callback: self).connect()
        }
    }
    
    /**
     BACKGROUND THREAD
     */
    func pushAuthentication(forToken: Token) {
        DispatchQueue.global(qos: .background).async {
            let req = forToken.pendingAuths.first! // TODO always the first
            // 0. Check TTL
            Utilities.log("push ttl is: \(req.ttl)")
            if req.ttl < Date() {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("push_auth_ttl_expired", comment: ""))
                forToken.removeAuthRequest(req)
                self.datasetChanged()
                U.log("ttl expired!")
                return
            }
            
            // 1. Verify signature
            let sslv = req.sslVerify ? "1" : "0"
            let toVerify = req.nonce + "|" + req.url + "|" + req.serial + "|" + req.question + "|" + req.title + "|" + sslv
            
            guard let key = Storage.shared.loadPIPubicKey(req.serial) else {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("publickey_not_found_message", comment: ""))
                U.log("no pi pub key found")
                return
            }
            
            if !Crypto.shared.verifySignature(signature: req.signature, message: toVerify, publicKey: key) {
                U.log("invalid signature")
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("signature_invalid", comment: ""))
                // the request is useless with the wrong signature, so it will be deleted.
                forToken.removeAuthRequest(req)
                self.datasetChanged()
                return
            }
            U.log("valid signature")
            // 2. Sign nonce + "|" + serial
            let toSign = req.nonce + "|" + req.serial
            
            guard let privateKey = Storage.shared.loadPrivateKey(req.serial) else {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("privatekey_not_found_message", comment: ""))
                U.log("privatekey is nil")
                return
            }
            guard let signature = Crypto.shared.signMessage(message: toSign, privateKey: privateKey) else {
                self.tableViewDelegate?.showMessageWithOKButton(title: "Error",
                                                                message: NSLocalizedString("signing_error", comment: ""))
                U.log("signing error")
                return
            }
            
            // 3. Assemble data and send it to privacyIDEA
            let params = [ "nonce": req.nonce,
                           "serial": req.serial,
                           "signature": signature ]
            Endpoint(url: req.url, data: params, sslVerify: req.sslVerify, token: forToken, callback: self).connect()
        }
    }
    
    func processFCMMessage(message: [AnyHashable : Any]) {
        // Required parameters
        guard let url = message["url"] else {
            U.log("No URL provided")
            return
        }
        guard let nonce = message["nonce"] else {
            U.log("No nonce provided")
            return
        }
        guard let signature = message["signature"] else {
            U.log("No signature provided")
            return
        }
        guard let serial = message["serial"]else {
            U.log("No serial provided")
            return
        }
        //
        guard let title = message["title"] else {
            U.log("No title provided")
            return
        }
        guard let question = message["question"] else {
            U.log("No question provided")
            return
        }
        
        var sslVerify = true
        if let sslVerifyInt = (message["sslverify"] as? NSString)?.integerValue {
            sslVerify = Bool(sslVerifyInt)
        }
        // TTL of a PushRequest is 2min ? // MARK: PUSH TTL
        let ttl: Date = Date().addingTimeInterval(Double(2) * 60.0)
        let id = UUID().uuidString
        let pushauthreq = PushAuthRequest(id: id, url: url as! String, nonce: nonce as! String, signature: signature as! String, serial: serial as! String, title: title as! String, question: question as! String, sslVerify: sslVerify, ttl: ttl)
        
        if addPushAuthRequestToToken(pushauthreq) {
            notificationManager?.buildNotification(forRequest: pushauthreq)
        }
    }
}
