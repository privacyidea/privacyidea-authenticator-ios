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
    
    func saveTokens(list: [Token]) -> Void {
        U.log("Saving tokenlist with size=\(list.count)")
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
            // Since metadata (the position in the list) can not be updated, the token is deleted and added again
            removeFromKeychain(key: token.serial)
            
            if let tmp = tokenToJSON(token) {
                //U.log("[SAVE TOKEN] \(tmp)")
                saveToKeychain(for: token.serial, tmp, String(i))
            }
            else {
                U.log("[SAVE TOKEN] Token \(list[i].label) could not be saved")
            }
        }
        U.log("Tokenlist saved.")
    }
    
    func saveToKeychain(for key: String, _ value: String, _ position: String)  {
        //U.log("saving position: \(position)")
        let password = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecValueData as String: password,
                                    kSecAttrLabel as String: position,
                                    //kSecAttrComment as String: position,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            if (status == errSecDuplicateItem) {
                U.log("Duplicate Item, updating...")
                let attr: [String: Any] =  [kSecAttrAccount as String: key,
                                            kSecValueData as String: password]
                //kSecAttrComment as String: position]
                
                let status2 = SecItemUpdate(query as CFDictionary, attr as CFDictionary)
                guard status2 == errSecSuccess else {
                    U.log("Error while updating: \(status.description)")
                    return
                }
            } else {
                U.log("Error while saving: \(status.description)")
            }
            return
        }
    }
    
    func listKeychainEntries() {
        let query: [String: Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecReturnData as String  : kCFBooleanTrue as Any,
            kSecReturnAttributes as String : kCFBooleanTrue as Any,
            kSecReturnRef as String : kCFBooleanTrue as Any,
            kSecMatchLimit as String : kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        
        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if lastResultCode == noErr {
            let array = result as? Array<Dictionary<String, Any>>
            for item in array! {
                if let key = item[kSecAttrAccount as String] as? String {
                    U.log("ITEM key: \(key)")
                }
            }
        }
    }
    
    func loadOldTokenFromKeychain() -> [String] {
        U.log("LOADING OLD TOKENS")
        let query: [String: Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecReturnData as String  : kCFBooleanTrue as Any,
            kSecReturnAttributes as String : kCFBooleanTrue as Any,
            kSecReturnRef as String : kCFBooleanTrue as Any,
            kSecMatchLimit as String : kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        
        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        var values = [String]()
        if lastResultCode == noErr {
            let array = result as? Array<Dictionary<String, Any>>
            for item in array! {
                if let key = item[kSecAttrAccount as String] as? String,
                    let value = item[kSecValueData as String] as? Data {
                    // Filter push token public/private keys or firebase config
                    if key.starts(with: "piPub") || key.starts(with: "private") || key.starts(with: Constants.FB_CONFIG) {
                        continue
                    }
                    // Load the old token
                    if key.starts(with: "token") {
                        values.append(String(data: value, encoding:.utf8)!)
                        
                    }
                    // Remove the old token from keychain
                    removeFromKeychain(key: key)
                }
            }
        }
        U.log("FOUND OLD TOKEN: \(values)")
        UserDefaults.standard.set(true, forKey: Constants.UPDATED)
        return values
    }
    
    func getAllTokenEntriesFromKeychain() -> [Int:String] {
        let query: [String: Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecReturnData as String  : kCFBooleanTrue as Any,
            kSecReturnAttributes as String : kCFBooleanTrue as Any,
            kSecReturnRef as String : kCFBooleanTrue as Any,
            kSecMatchLimit as String : kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        
        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            
        }
        
        var values = [Int:String]()
        if lastResultCode == noErr {
            let array = result as? Array<Dictionary<String, Any>>
            
            for item in array! {
                if let key = item[kSecAttrAccount as String] as? String,
                    let value = item[kSecValueData as String] as? Data {
                    // Filter push token public/private keys or firebase config
                    if key.starts(with: "piPub") || key.starts(with: "private") || key.starts(with: Constants.FB_CONFIG) {
                        continue
                    }
                    //U.log("ITEM: \(item)")
                    guard let position = Int(item[kSecAttrLabel as String] as? String ?? "") else {
                        //U.log("position is not an int: \(item[kSecAttrService as String] as? String ?? "")")
                        continue
                    }
                    U.log("FOUND label(pos): \(position)")
                    values[position] = String(data: value, encoding:.utf8)
                }
            }
        }
        return values
    }
    
    func removeFromKeychain(key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                U.log("Item to be deleted was not found (\(key))")
            } else {
                U.log("Error while removing: \(status.description)")
            }
            return
        }
        U.log("Item with key=\(key) deleted succesfully")
    }
    
    func clearKeychain() {
        let secItemClasses =  [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            let status = SecItemDelete(spec)
            if status == errSecSuccess {
                U.log("cleared keychain")
            } else {
                U.log("clear keychain error: \(status)")
            }
        }
    }
    
    func loadTokens()-> [Token] {
        var ret:[Token] = []
        /////////// LOADING OLD DATA /////////////////
        if !UserDefaults.standard.bool(forKey: Constants.UPDATED) {
            let strings = loadOldTokenFromKeychain()
            for s in strings {
                if let token = jsonToToken(str: s) {
                    ret.append(token)
                }
            }
        }
        var oldTokenPresent = false
        if ret.count > 0 {
            oldTokenPresent = true
        }
        /////////// END LOADING OLD DATA /////////////
        let dict = getAllTokenEntriesFromKeychain()
        U.log("Found dict: \(dict as AnyObject)")
      
        for i in 0..<dict.count {
            if let json = dict[i] {
                if let tmp = jsonToToken(str: json) {
                    ret.append(tmp)
                } else {
                    U.log("could not decode token: \(json)")
                }
            } else {
                U.log("nothing found at \(i)")
            }
        }
        /////////// LOADING OLD DATA /////////////////
        if oldTokenPresent {
            saveTokens(list: ret)
        }
        /////////// END LOADING OLD DATA /////////////
        return ret
    }
    
    func tokenToJSON(_ token: Token) -> String? {
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
    
    func jsonToToken(str: String) -> Token? {
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
    
    // MARK: FIREBASE + TOKEN
    func saveFirebaseConfig(_ config: FirebaseConfig) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(config)
            let str = String(data: data, encoding: .utf8)!
            U.log("Saving Firebase Config: \(str)")
            KeychainSwift().set(str, forKey: Constants.FB_CONFIG, withAccess: .accessibleAlwaysThisDeviceOnly)
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
    
    // MARK: PRIVATE + PUBLIC KEYS
    func savePrivateKey(serial: String, privateKey: SecKey) {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            U.log(error!.takeRetainedValue() as Error)
            return
        }
        KeychainSwift().set(data.base64EncodedString(), forKey: "private" + serial, withAccess: .accessibleAlwaysThisDeviceOnly)
        U.log("Saving Private Key for \(serial)")
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
            KeychainSwift().set(publicKeyStr, forKey: "piPub" + serial, withAccess: .accessibleAlwaysThisDeviceOnly)
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
