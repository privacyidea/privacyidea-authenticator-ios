//
//  Model.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 09.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import SwiftOTP


class Model {
    private var tokenlist: [Token] = []
    
    init(token: [Token]) {
        self.tokenlist.append(contentsOf: token)
        for t in tokenlist {
            if t.type != Tokentype.PUSH {
                t.currentOTP = OTPGenerator.generate(t)
            }
        }
    }
    
    func refreshTOTP() {
        for t in tokenlist {
            if (t.type == Tokentype.TOTP) {
                t.currentOTP = OTPGenerator.generate(t)
            }
        }
    }
    
    func increaseHOTP(index: Int) {
        let token = tokenlist[index]
        if(token.type != Tokentype.HOTP)
        { return }
        if token.counter != nil {
            token.counter! += 1
        } else { token.counter = 1 }
        token.currentOTP = OTPGenerator.generate(token)
    }
    
    func addToken(_ token: Token) {
        if !(token.type == Tokentype.PUSH) {
            token.currentOTP = OTPGenerator.generate(token)
        }
        tokenlist.append(token)
    }
    
    func getTokenBySerial(_ serial: String) -> Token? {
        for t in tokenlist {
            if t.serial == serial { return t }
        }
        return nil
    }
    
    func getList() -> [Token] {
        return tokenlist
    }
    
    func getListCount() -> Int {
        return tokenlist.count
    }
    
    func hasPushtokenLeft() -> Bool {
        for t in tokenlist {
            if t.type == Tokentype.PUSH {
                return true
            }
        }
        return false
    }
    
    func getTokenAt(_ index: Int) -> Token {
        return tokenlist[index]
    }
    
    func removeTokenAt(_ index: Int) -> Token {
        return tokenlist.remove(at: index)
    }
    
    func removeToken(_ t: Token) {
        tokenlist = tokenlist.filter() {
            $0 !== t
        }
    }
    
    func insertTokenAt(token: Token, at: Int) {
        tokenlist.insert(token, at: at)
    }
    
    func checkExpiredRollouts() -> [Token]? {
        return tokenlist.filter({ (t) -> Bool in
            return (t.type == Tokentype.PUSH && t.expirationDate! < Date() && t.getState() == State.UNFINISHED)
        })
    }
    
    /**
     Returns the IDs of expired authentication requests to delete their notifications
     */
    func checkExpiredAuthRequests() -> [String]? {
        var removedIDs: [String] = []
        for t in tokenlist {
            if t.type == Tokentype.PUSH {
                for a in t.pendingAuths {
                    if a.ttl < Date() {
                        t.removeAuthRequest(a)
                        removedIDs.append(a.id)
                    }
                }
            }
        }
        if removedIDs.count > 0 {
            return removedIDs
        }
        return nil
    }
    
}
