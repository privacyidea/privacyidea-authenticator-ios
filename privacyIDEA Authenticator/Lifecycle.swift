//
//  Lifecycle.swift
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 17.06.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

import Foundation

extension Presenter: PresenterLifecycleDelegate {
    func fcmMessageReceived(message: [AnyHashable : Any]) {
        // Pass the message through
        processFCMMessage(message: message)
    }
    
    func applicationDidEnterBackground() {
        saveTokenlist()
    }
    
    func applicationWillResignActive() {
        
    }
    
    func applicationWillEnterForeground() {
        
    }
    
    func applicationDidBecomeActive() {
        model.refreshTOTP()
        tableViewDelegate?.reloadCells()
    }
    
    func applicationWillTerminate() {
        saveTokenlist()
    }
}
