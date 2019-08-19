//
//  Endpoint.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 29.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation

class Endpoint: NSObject, URLSessionDelegate {
    private var url: String
    private var callback: EndpointCallback
    private var data: [String : String]
    private var sslVerify: Bool
    private var token: Token
    
    init(url: String, data: [String : String], sslVerify: Bool, token: Token, callback: EndpointCallback) {
        self.url = url
        self.data = data
        self.sslVerify = sslVerify
        self.callback = callback
        self.token = token
        //U.log("endpoint with SSLVerify=\(sslVerify)")
    }
    
    func connect() {
        U.log("Connecting to \(url)")
        DispatchQueue.global(qos: .background).async {
            
            let url = URL(string: self.url)!
            var session: URLSession
            
            if !self.sslVerify {
                session = URLSession(configuration: .default, delegate: self, delegateQueue: nil) }
            else {
                session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil) }
            
            var request = URLRequest(url: url)
            // timeout is 60s by default
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: self.data, options: .prettyPrinted)
            } catch let error {
                U.log("parameters could not be serialized: \(error.localizedDescription)")
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    U.log("error while sending:")
                    self.token.setLastestError(error)
                    self.callback.errorOccured(self.token)
                    return
                }
                
                guard let data = data else {
                    U.log("data error")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        //U.log("Response: \(json)")
                        self.callback.responseReceived(response: json, self.token)
                        
                    }
                } catch let error {
                    U.log("response cannot be serialized to json: \(error.localizedDescription)")
                    self.token.setLastestError(error)
                    self.callback.errorOccured(self.token)
                }
            })
            task.resume()
        }
    }
    
    // Use self as URLSessionDelegate if SSLVerify should be turned off, so this method is called
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, credential)
    }
}

