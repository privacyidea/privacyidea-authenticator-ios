//
//  Crypto.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 10.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import SwiftyRSA
import SwiftOTP

class Crypto {
    
    static let shared = Crypto()
    
    private init () {}
    
    // Generate a Keypair, which is stored with the serial as alias
    // Return the PublicKey as b64String
    func generateKeypair(_ serial: String) -> String {
        U.log("Generating Keypair for serial \(serial)...")
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(Constants.keyPairAttr as CFDictionary, &error) else {
            U.log("Error while generating keys:")
            U.log(error!.takeRetainedValue() as Error)
            return ""
        }
        
        Storage.shared.savePrivateKey(serial: serial, privateKey: privateKey)
        
        let publicKey = SecKeyCopyPublicKey(privateKey)!
        guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            U.log(error!.takeRetainedValue() as Error)
            return ""
        }
        return data.base64EncodedString()
    }
    
    // maybe throw stuff here
    func stringToPrivateKey(_ str: String) -> SecKey? {
        var error: Unmanaged<CFError>?
        
        guard let data = stringToNSData(str) else {
            U.log("String not in Base64 format: \(str)")
            return nil
        }
        
        guard let key = SecKeyCreateWithData(data, Constants.privKeyAttr as CFDictionary, &error) else {
            U.log(error!.takeRetainedValue() as Error)
            return nil
        }
        return key
    }
    
    func stringToPublicKey(_ str: String) -> SecKey? {
        var error: Unmanaged<CFError>?
        guard let data = stringToNSData(str) else {
            U.log("String not in Base64 format: \(str)")
            return nil
        }
        guard let key = SecKeyCreateWithData(data, Constants.pubKeyAttr as CFDictionary, &error) else {
            U.log(error!.takeRetainedValue() as Error)
            return nil
        }
        return key
    }
    
    func validateStringIsPublicKey(_ str: String) -> Bool {
        guard let publicKey = Crypto.shared.stringToPublicKey(str) else {
            U.log("Received String could not be converted to a PublicKey")
            return false
        }
        
        var error: Unmanaged<CFError>?
        guard (SecKeyCopyExternalRepresentation(publicKey, &error) as Data?) != nil else {
            U.log(error!.takeRetainedValue() as Error)
            U.log("Received String could be converted to a PublicKey, but not be exported")
            return false
        }
        return true
    }
    
    private func stringToNSData(_ str: String) -> NSData? {
        return NSData(base64Encoded: str,
                      options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
    }
    
    /**
     Verify the signature of the given message with the given publicKey
     
     - Parameter signature: The signature to verify (expected in base32 format)
     - Parameter message:   The message the signature was created for
     - Parameter publicKey: The publicKey to verify with
     
     - Returns: True or false
     */
    func verifySignature(signature: String, message: String, publicKey: SecKey) -> Bool {
        guard let data = base32DecodeToData(signature) else {
            U.log("Decoding signature error")
            return false
        }
        do {
            let sign = Signature(data: data)
            let clear = try  ClearMessage(string: message, using: .utf8)
            let pubKey = try PublicKey(reference: publicKey)
            
            return try clear.verify(with: pubKey, signature: sign, digestType: .sha256)
        } catch {
            U.log("validation error \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     Sign the message with the given private Key
     
     -Parameter message:    Message to sign
     -Parameter privateKey: Private Key to sign with
     
     -Returns: The signature in BASE32 FORMAT or nil upon error
     */
    func signMessage(message: String, privateKey: SecKey) -> String? {
        do {
            let msg = try ClearMessage(string: message, using: .utf8)
            let key = try PrivateKey(reference: privateKey)
            let signature = try msg.signed(with: key, digestType: .sha256)
            let data = signature.data
            return base32Encode(data)
        } catch {
            U.log(error.localizedDescription)
            return nil
        }
    }
    
}
