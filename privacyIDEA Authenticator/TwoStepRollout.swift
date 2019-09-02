//
//  TwoStepRollout.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 15.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import CommonCrypto
import SwiftOTP

class TwoStepRollout {
    
    var listViewDelegate: TokenlistDelegate
    
    init(_ delegate: TokenlistDelegate) {
        self.listViewDelegate = delegate
    }
    
    // MARK: - 2STEP
    func do2stepinit(t:Token, salt_size:Int, difficulty:Int, output:Int) -> Token {
        // 1. Generate random bytes equal to the "salt" aka phonepart size
        var phonepart = [UInt8](repeating: 0, count: salt_size) // array to hold randoms bytes
        
        // Generate random bytes
        let res = SecRandomCopyBytes(kSecRandomDefault, salt_size, &phonepart)
        if res != errSecSuccess {
            U.log("random byte generation failed")
            listViewDelegate.showMessageWithOKButton(title: NSLocalizedString("2step_byte_generation_failed_title", comment: ""),
                                                     message: NSLocalizedString("2step_byte_generation_failed_message", comment: ""))
            return t
        }
        
        //U.log("token secret before: \(t.secret!.toHexString())")
        //U.log("phonepart as hex: \(phonepart.toHexString())")
        
        // 2. PDBKDF2 with the specified parameters
        
        let password = t.secret!.toHexString()
        
        let derivedKeyData: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: (output/8))
        
        _ = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, password.count, phonepart, phonepart.count,
                                      CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1), UInt32(difficulty), derivedKeyData, (output/8))
        let dat = Data(bytes: derivedKeyData, count: (output/8))
        
        //U.log("CCKeyDerivationPBKDF result: \(cs)")
        //U.log("complete secret: \(dat.toHexString())")
        
        t.secret = dat
        
        /* 3. Build the result to show to the user as follows:
         The first 4 characters of the sha1 hash of the client (phone's) part as checksum.
         client_part being the binary random value that the client (phone) generated:
         b32encode( sha1(client_part)[0:3] + client_part )
         */
        
        let hash = phonepart.sha1()
        var chksm:Array<UInt8> = Array(hash.prefix(4))
        //let chksm_b32 = base32Encode(chksm)
        U.log("chksm b32: \(base32Encode(chksm))")
        U.log("phonepart b32: \(base32Encode(phonepart))")
        chksm.append(contentsOf: phonepart)
        
        let chksm_b32 = base32Encode(chksm)
        
        // Put a ' ' after each 4 digits
        let split_text = String(chksm_b32.enumerated().map{ $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1] }.joined())
        // Remove the padding characters
        let toshow = split_text.replacingOccurrences(of: "=", with: "")
        
        U.log("show to user: \(toshow)")
        
        // 4. Open dialog and show the phonepart to the user
        listViewDelegate.showMessageWithOKButton(title: NSLocalizedString("2step_phonepart_dialog_title", comment: "2step phone part of secret"), message: toshow)
        
        return t
    }
}

