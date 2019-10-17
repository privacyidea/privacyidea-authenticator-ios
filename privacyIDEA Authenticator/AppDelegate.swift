//
//  AppDelegate.swift
//  test
//
//  Created by Nils Behlen on 07.08.18.""
//  Copyright © 2018 Nils Behlen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import KeychainSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var presenterDelegate: PresenterLifecycleDelegate?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Analytics.setAnalyticsCollectionEnabled(false)
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        
        // Check to see if content protection is active before going further
        // Should fix random token deletion
        var loopCount = 0
        while (!application.isProtectedDataAvailable) {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
            loopCount += 1
        }
        
        _ = Presenter.shared //ensure instance is instantiated and push delegate is set
        
        U.log("didFinishLaunchingWithOptions: \(String(loopCount)) \(String(describing: launchOptions))")
        if let userInfo = launchOptions?[.remoteNotification] as?  [AnyHashable : Any] {
            // Notification received upon launch, app may have been terminated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.presenterDelegate?.fcmMessageReceived(message: userInfo)
            }
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        presenterDelegate?.applicationWillResignActive()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        presenterDelegate?.applicationDidEnterBackground()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        presenterDelegate?.applicationWillEnterForeground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        presenterDelegate?.applicationDidBecomeActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        presenterDelegate?.applicationWillTerminate()
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /* U.log("Setting APN Token to device Token")
         let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X",    $1)})
         U.log("deviceToken: \(tokenString)")
         Messaging.messaging().apnsToken = deviceToken */
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        
        // MARK: PRINT PUSH DATA
        U.log(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will be fired.
        
        U.log(userInfo)
        presenterDelegate?.fcmMessageReceived(message: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
}

