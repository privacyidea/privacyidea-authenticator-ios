//
//  AboutViewController.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 04.10.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class AboutViewController: UIViewController
{
    
    private let thirdPartyLibs: [String] = ["KeychainSwift", "CryptoSwift", "SwiftOTP" , "ToastSwift", "Google Firebase"]
    
    @IBOutlet weak var thirdPartyLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var stackView: UIStackView!
    override func viewDidLoad(){
        // Put a button for each lib in the stackview
       webView.isHidden = true
        for i in 0..<thirdPartyLibs.count {
            let button = UIButton(type: .custom)
            button.tag = i
            button.setTitle(thirdPartyLibs[i], for: .normal)
            button.addTarget(self, action: #selector(action), for: .touchUpInside)
            button.backgroundColor = Constants.PI_BLUE
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc func action(_ sender: UIButton!) {
        webView.isHidden = false
        let resName: String = thirdPartyLibs[sender.tag] + " license"
        if let url = Bundle.main.url(forResource: resName, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            U.log("License file not found for: \(resName)")
        }
    }
}
