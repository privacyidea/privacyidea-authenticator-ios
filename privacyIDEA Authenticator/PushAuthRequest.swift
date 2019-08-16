//
//  PushAuthRequest.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 10.05.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation


class PushAuthRequest: Codable {
    
    var url: String
    var nonce: String
    var signature: String
    var serial: String
    var title: String
    var question: String
    var sslVerify: Bool
    var ttl: Date
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url"
        case nonce = "nonce"
        case signature = "signature"
        case serial = "serial"
        case title = "title"
        case question = "question"
        case sslVerify = "sslverify"
        case ttl = "ttl"
        case id = "id"
    }
    
    init(id: String, url: String, nonce: String, signature: String, serial: String, title: String, question: String, sslVerify: Bool, ttl: Date) {
        self.url = url
        self.nonce = nonce
        self.signature = signature
        self.serial = serial
        self.title = title
        self.question = question
        self.sslVerify = sslVerify
        self.ttl = ttl
        self.id = id
        U.log("new req with ttl: \(ttl)")
    }
}
