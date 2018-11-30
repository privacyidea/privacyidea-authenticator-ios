//
//  AboutViewController.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 04.10.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController: UIViewController
{
    @IBOutlet weak var wVKeychainSwift: UIWebView!
    @IBOutlet weak var wVSwiftOTP: UIWebView!
    @IBOutlet weak var wVCryptoSwift: UIWebView!
    
    override func viewDidLoad(){
        // KEYCHAINSWIFT
        do {
            guard let filePath = Bundle.main.path(forResource: "KeychainSwift license", ofType: "html")
            else { print ("File reading error: KeyChainSwift license")
                return }
            
            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            wVKeychainSwift.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error: KeyChainSwift license")
        }
        // CRYPTO SWIFT
        do {
            guard let filePath = Bundle.main.path(forResource: "CryptoSwift license", ofType: "html")
                else { print ("File reading error: CryptoSwift license")
                    return }
            
            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            wVCryptoSwift.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error: CryptoSwift license")
        }
        // SWIFT OTP
        do {
            guard let filePath = Bundle.main.path(forResource: "SwiftOTP license", ofType: "html")
                else { print ("File reading error: SwiftOTP license")
                    return }
            
            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            wVSwiftOTP.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error: SwiftOTP license")
        }
    }
}
