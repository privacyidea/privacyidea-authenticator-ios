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
    var serial: String
    var label: String
    
    var digits: Int?
    var algorithm: String?
    var secret: Data?
    var counter: Int?
    var period: Int?
    var currentOTP: String?
    
    var enrollment_credential: String?
    var enrollment_url: String?
    var expirationDate: Date?
    var sslVerify: Bool?
    private var state: String
    private var latestError: Error?
    
    var pendingAuths: [PushAuthRequest]
    
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case digits = "digits"
        case algorithm = "algorithm"
        case secret = "secret"
        case label = "label"
        case counter = "counter"
        case period = "period"
        case serial = "serial"
        case enrollment_credential = "enrollment_credential"
        case enrollment_url = "enrollment_url"
        case expirationDate = "expirationDate"
        case sslVerify = "sslVerify"
        case state = "state"
        case pendingAuths = "pendingAuths"
    }
    
    // Initialize the token with the given values. Usable defaults are:
    // Digits = 6, Counter = 1 (for HOTP), Period = 30 (for TOTP), Algorithm = SHA1
    init(type: String,label: String, serial: String, digits: Int = 6, algorithm: String = "sha1", secret: Data,  counter: Int = 1, period: Int?) {
        self.type = type
        self.label = label
        self.serial = serial
        
        self.algorithm = algorithm
        self.secret = secret
        self.counter = counter
        self.digits = (digits == 6) ? 6 : 8
        // validate the interval and set it
        if type == Tokentype.TOTP {
            if period != nil {
                if period! == 30 || period! == 60 {
                    self.period = period!
                } else { self.period = 30 }
            } else { self.period = 30 }
        } else {
            self.period = nil
        }
        
        self.pendingAuths = []
        self.state = State.FINISHED
    }
    
    // Push initializer
    init(type: String, label: String, serial: String, enrollment_credential: String, enrollment_url: String, expirationDate: Date, state: String){
        self.type = type
        self.label = label
        self.serial = serial
        self.enrollment_url = enrollment_url
        self.enrollment_credential = enrollment_credential
        self.expirationDate = expirationDate
        self.sslVerify = true
        self.state = state
        
        self.pendingAuths = []
    }
    
    func hasPendingAuths() -> Bool {
        return self.pendingAuths.count > 0
    }
    
    func isStillValid(_ pushAuthRequest: PushAuthRequest) -> Bool {
       return pushAuthRequest.ttl > Date()
    }
    
    func removeAuthRequest(_ req: PushAuthRequest) {
        self.pendingAuths = self.pendingAuths.filter( {
            
            if($0 !== req) {
                U.log("removing \($0.question)")
                return true
            }
            return false
        } )
    }
    
    func setState(_ newState: String) {
        U.log("State of \(label): \(self.state) -> \(newState)")
        self.state = newState
    }
    
    func getState() -> String {
        return state
    }
    
    func setLastestError(_ error: Error?) {
        error != nil ? U.log("\(label): new error: \(error!.localizedDescription)") : U.log("\(label) resetting error")
        self.latestError = error
    }
    
    func getLastestError() -> Error? {
        return latestError
    }
}
