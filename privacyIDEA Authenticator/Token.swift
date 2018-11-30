//
//  Token.swift
//  test
//
//  Created by Nils Behlen on 07.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import Foundation

class Token: Codable {

    var type: String
    var digits: Int
    var algorithm: String
    var secret: Data
    var label: String
    var counter: Int?
    var period: Int?

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case digits = "digits"
        case algorithm = "algorithm"
        case secret = "secret"
        case label = "label"
        case counter = "counter"
        case period = "period"
    }
    // Initialize the token with the given values. Usable defaults are:
    // Digits = 6, Counter = 1 (for HOTP), Period = 30 (for TOTP), Algorithm = SHA1

    init(type: String, digits: Int = 6, algorithm: String = "sha1", secret: Data, label: String, counter: Int = 1, period: Int?) {
        self.algorithm = algorithm
        self.secret = secret
        self.type = type
        self.label = label
        self.counter = counter
        self.digits = 6
        // validate digits to be between 6 and 8
        if digits <= 8 && digits >= 6 {
            self.digits = digits
        }
        if digits > 8 { self.digits = 8 }
        // validate the interval and set it
        if type == "totp" {
            if period != nil {
                if period! == 30 || period! == 60 {
                    self.period = period!
                } else { self.period = 30 }
            } else { self.period = 30 }
        } else {
            self.period = nil
        }
    }
}
