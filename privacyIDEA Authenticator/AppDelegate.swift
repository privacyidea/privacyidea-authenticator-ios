//
//  AppDelegate.swift
//  test
//
//  Created by Nils Behlen on 07.08.18.
//  Copyright © 2018 Nils Behlen. All rights reserved.
//  Updated Vadim Zavjalov, Pharos Production Inc. on 30.04.19.
//

import UIKit
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Variables
    
    var window: UIWindow?
    var tableVC: TableViewController?
    
    // Life
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setupFirebase()
        registerForPushNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        setupApnsWithToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        tableVC?.saveTokenlist()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        tableVC?.saveTokenlist()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        tableVC?.refreshTokenlist()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        tableVC?.saveTokenlist()
    }
    
    // Private
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupApnsWithToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func registerForPushNotifications() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

