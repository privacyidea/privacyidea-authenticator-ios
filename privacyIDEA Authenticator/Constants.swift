//
//  Constants.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 09.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import UIKit

typealias Tokentype = Constants.Tokentype
typealias State = Constants.State

struct Constants {
    
    struct Tokentype {
        static let PUSH = "pipush"
        static let TOTP = "totp"
        static let HOTP = "hotp"
    }
    
    struct State {
        static let UNFINISHED = "unfinished"    // Allow to retry enrollment (push)
        static let FINISHED = "finished"        // Base state
        static let ENROLLING = "enrolling"
        static let AUTHENTICATING = "authenticating"
    }
    
    static let FB_CONFIG = "firebaseconfig"
    static let PUSHTOKEN_LABEL = "Pushtoken"
    
    static let pubKeyAttr: [String: Any] =
        [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
         kSecAttrKeySizeInBits as String:      4096,
         kSecAttrKeyClass as String:           kSecAttrKeyClassPublic]
    
    static let privKeyAttr: [String: Any] =
        [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
         kSecAttrKeySizeInBits as String:      4096,
         kSecAttrKeyClass as String:           kSecAttrKeyClassPrivate]
    
    static let keyPairAttr: [String: Any] =
        [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
         kSecAttrKeySizeInBits as String:      4096]
    
    static let TOAST_UPTIME_IN_S = 2.0
    
    static let PI_BLUE = UIColor(red: 0.670465749, green: 0.8777691889, blue: 1, alpha: 1)
    
}
