//
//  FirebaseConfig.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 15.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation

class FirebaseConfig: Codable {
    
    var projID: String = ""
    var appID: String = ""
    var api_key: String = ""
    var projNumber: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case projID = "projID"
        case appID = "appID"
        case api_key = "api_key"
        case projNumber = "projNumber"
    }
    
    init(projID:String, appID:String, api_key:String, projNumber:String) {
        self.projID = projID
        self.appID = appID
        self.api_key = api_key
        self.projNumber = projNumber
    }
}
