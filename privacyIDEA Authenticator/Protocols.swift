//
//  Protocols.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 09.04.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation
import UIKit

protocol TokenlistDelegate {
    func reloadCells()
    func updateProgressbar(indexPath: IndexPath, progress: Int)
    func showMessageWithOKButton(title: String, message: String)
    func showToastMessage(text: String)
    // TODO alert builder via interface
}

@objc protocol PresenterCellDelegate {
    @objc func retryRollout(_ sender: UIButton)
    @objc func confirmedPushAuthentication(_ sender: UIButton)
}

protocol PresenterDelegate {
    func startup()
    func timerProgress(seconds: Int)
    func getTokenForRow(index: Int) -> Token
    func removeTokenAt(index: Int)
    func getListCount() -> Int
    func switchTokenPositions(src_index: Int, dest_index: Int)
    func addManuallyFinished(token: Token)
    func changeTokenLabel(_ label: String, index: Int)
}

protocol PresenterLifecycleDelegate {
    func applicationDidEnterBackground()
    func applicationWillResignActive()
    func applicationWillEnterForeground()
    func applicationDidBecomeActive()
    func applicationWillTerminate()
    
    func fcmMessageReceived(message: [AnyHashable: Any])
}

protocol QRScanResultDelegate {
    func passScanResult(code:String)
}

protocol EndpointCallback {
    func errorOccured(_ token: Token)
    func responseReceived(response: [String : Any], _ token: Token)
}


// MARK: EXTENSION TO USE STRING AS ERROR
extension String: Error, LocalizedError {
    public var errorDescription: String? { return self }
}

extension Bool {
    init(_ intValue: Int) {
        self = intValue == 1
    }
}

extension Bool {
    init(_ strValue: String) {
        self = strValue == "1"
    }
}
