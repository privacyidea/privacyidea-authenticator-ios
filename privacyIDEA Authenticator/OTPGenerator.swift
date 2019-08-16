//
//  OTPGenerator.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 09.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import SwiftOTP

class OTPGenerator {
    
    static func generate(_ token: Token) -> String {
        if (token.type == Tokentype.PUSH) {
            return ""
        }
        
        let algo: OTPAlgorithm = getOTPAlgorithm(token)
        
        if token.type == Tokentype.HOTP {
            let x = HOTP(secret: token.secret!, digits: token.digits!, algorithm: algo)!
            return x.generate(counter: UInt64(token.counter!))!
        }
        else {
            let x = TOTP(secret: token.secret!, digits: token.digits!, timeInterval: token.period!, algorithm: algo)!
            let date = Int(Date().timeIntervalSince1970)
            return x.generate(secondsPast1970: date)!
        }
    }
    
    // convert Token.algorithm to OTPAlgorithm
    static func getOTPAlgorithm(_ t: Token) -> OTPAlgorithm {
        if t.algorithm == "sha256" { return .sha256 }
        else if (t.algorithm == "sha512") { return .sha512 }
        else { return .sha1 }
    }
}
