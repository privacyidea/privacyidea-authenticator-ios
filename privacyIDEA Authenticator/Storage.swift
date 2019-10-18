//
//  Storage.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 10.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.

import Foundation
import KeychainSwift

class Storage {
    
    static let shared = Storage()
    
    private init(){ }
    
    // MARK: TOKENLIST
    func saveTokens(list: [Token]) -> Void {
        let keychain = KeychainSwift()
        UserDefaults.standard.set(list.count, forKey: "token_count")
        
        for i in 0..<list.count {
            // Check the token state, don't save in ENROLLING or AUTHENTICATING state
            // This DOES NOT use a copy of the token, so the list needs to be saved before going into
            // one of the states that is overwritten!!!
            let token = list[i]
            if token.type == Tokentype.PUSH {
                if token.getState() == State.AUTHENTICATING {
                    // becomes finished, token was rolled out
                    token.setState(State.FINISHED)
                }
                if token.getState() == State.ENROLLING {
                    // becomes unfinished, rollout was interrupted
                    token.setState(State.UNFINISHED)
                }
            }
            if let tmp = tokenToJSON(token) {
                //U.log("[SAVE TOKEN] \(tmp)")
                keychain.set(tmp, forKey: "token\(i)")
            }
            else {
                U.log("[SAVE TOKEN] Token \(list[i].label) could not be saved")
            }
        }
        U.log("Tokenlist saved.")
    }
    
    func loadTokens()-> [Token] {
        let count = UserDefaults.standard.integer(forKey: "token_count")
        let keychain = KeychainSwift()
        var tokens:[Token] = []
        for i in 0..<count {
            if let tmp = keychain.get("token\(i)"){
                if let tmp2 = jsonToToken(str: tmp){
                    tokens.append(tmp2)
                }
            } else {
                U.log("[LOAD TOKEN] Could not load token \(i) of \(count)")
            }
        }
        return tokens
    }
    
    private func tokenToJSON(_ token: Token) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(token)
            return String(data: data, encoding: .utf8)!
        } catch {
            U.log("[ENCODE] Token \(token.label) cannot be encoded: \(error)")
        }
        return nil
    }
    
    private func jsonToToken(str: String) -> Token? {
        let decoder = JSONDecoder()
        if let t = try? decoder.decode(Token.self, from: str.data(using: .utf8)!) {
            return t
        } else {
            // Try to load as an old token, then copy it to the new format
            if let t = try? decoder.decode(TokenOld.self, from: str.data(using: .utf8)!) {
                // Make a new token out of the old
                // Serial was added in the new format to the serial of these will be their current label
                // Since there were only hotp/totp, the serial is not used anyway
                let newToken: Token = Token(type: t.type, label: t.label, serial: t.label, secret: t.secret, period: t.period)
                return newToken
            } else {
                U.log("[DECODE] Token \(str) cannot be decoded")
                return nil
            }
        }
    }
    
    // MARK: FIREBASE+TOKEN
   func saveFirebaseConfig(_ config: FirebaseConfig) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(config)
            let str = String(data: data, encoding: .utf8)!
            //U.log("Saving Firebase Config: \(str)")
            KeychainSwift().set(str, forKey: Constants.FB_CONFIG, withAccess: .accessibleAfterFirstUnlock)
        } catch {
            U.log("[ENCODE] FirebaseConfig cannot be encoded \(error)")
        }
    }
    
    func loadFirebaseConfig() -> FirebaseConfig? {
        if let str = KeychainSwift().get(Constants.FB_CONFIG) {
            let decoder = JSONDecoder()
            if let config = try? decoder.decode(FirebaseConfig.self, from: str.data(using: .utf8)!) {
                U.log("Loading Firebase Config: \(str)")
                return config
            } else {
                U.log("[DECODE] FirebaseConfig \(str ) cannot be decoded")
                return nil
            }
        } else {
            U.log("No Firebase Config found")
            return nil
        }
    }
    
    func deleteFirebaseConfig() {
        if KeychainSwift().delete(Constants.FB_CONFIG) {
            U.log("Firebase Config deleted")
        }
    }
    
    // MARK: PRIVATE+PUBLIC KEYS
    func savePrivateKey(serial: String, privateKey: SecKey) {
        U.log("Saving Private Key for \(serial)")
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            U.log(error!.takeRetainedValue() as Error)
            return
        }
        KeychainSwift().set(data.base64EncodedString(), forKey: "private" + serial, withAccess: .accessibleAfterFirstUnlock)
    }
    
    func loadPrivateKey(_ serial: String) -> SecKey? {
        U.log("Loading Private Key for \(serial)...")
        guard let str = KeychainSwift().get("private" + serial) else {
            U.log("No key data found.")
            return nil
        }
        return Crypto.shared.stringToPrivateKey(str)
    }
    
   func savePIPublicKey(serial: String, publicKeyStr: String) -> Bool {
        // Decode the b64String to SecKey before storing to ensure it's a valid key
        let keyStr = Utilities().b64URLSafeTob64(publicKeyStr)
        if Crypto.shared.validateStringIsPublicKey(keyStr) {
            KeychainSwift().set(publicKeyStr, forKey: "piPub" + serial, withAccess: .accessibleAfterFirstUnlock)
            U.log("Public Key for \(serial) stored")
            return true
        }
        return false
    }
    
    func loadPIPublicKey(_ serial: String) -> SecKey? {
        U.log("Loading PIs Public Key for \(serial)...")
        guard let str = KeychainSwift().get("piPub" + serial) else {
            U.log("No key data found.")
            return nil
        }
        return Crypto.shared.stringToPublicKey(str)
    }
    
    func removeKeysFor(_ serial: String) {
        let keychain = KeychainSwift()
        keychain.delete("piPub" + serial)
        keychain.delete("private" + serial)
        U.log("Keys for \(serial) deleted")
    }
}
