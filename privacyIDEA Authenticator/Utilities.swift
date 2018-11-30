//
// Created by Nils Behlen on 31.08.18.
// Copyright (c) 2018 Nils Behlen. All rights reserved.
//

import Foundation
import KeychainSwift

class Utilities {

    init(){ }

    func saveTokens(list:[Token]) -> Void {
        let keychain = KeychainSwift()
        UserDefaults.standard.set(list.count, forKey: "token_count")

        for i in 0..<list.count {
            if let tmp = tokenToJSONString(token: list[i]){
                keychain.set(tmp, forKey: "token\(i)")
            }
            else {
                print("[SAVE TOKEN] Token \(list[i].label) could not be saved")
            }
        }
    }

    func loadTokens()-> [Token] {
        let count = UserDefaults.standard.integer(forKey: "token_count")
        let keychain = KeychainSwift()
        var tokens:[Token] = []
        for i in 0..<count {
            if let tmp = keychain.get("token\(i)"){
                if let tmp2 = jsonStringToToken(str: tmp){
                    tokens.append(tmp2)
                }
            } else {
                print("[LOAD TOKEN] Could not load token \(i) of \(count)")
            }
        }
        return tokens
    }


/**
    Encode a token to a string in JSON format
*/
   private func tokenToJSONString(token: Token) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(token)
            let res = String(data: data, encoding: .utf8)!
            return res
        } catch {
            print("[ENCODE] Token \(token.label) cannot be encoded: \(error)")
        }
        return nil
    }

/**
    Decode an array of Strings in JSON format to an array of tokens
*/
    private func jsonStringToToken(str: String) -> Token? {
        let decoder = JSONDecoder()
        if let t = try? decoder.decode(Token.self, from: str.data(using: .utf8)!) {
            return t
        } else {
            print("[DECODE] Token \(str) cannot be decoded")
        }
        return nil
    }

}

