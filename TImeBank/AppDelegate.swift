//
//  AppDelegate.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import TMMSDK
import Moya
import SwiftyUserDefaults
import TACCore
import TACMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin])
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options:[.badge, .sound, .alert]) {_,_ in
        }
        
        let tmmBeacon = TMMBeacon.initWithKey("e515a8899e7a43944a68502969154e4cb87a03a3", secret: "47535bf74a8072c0b6246b4fb73508eeb12f5982")
        tmmBeacon?.start()
        
        let options = TACApplicationOptions.default()
        options?.analyticsOptions.idfa = tmmBeacon?.deviceId()
        TACApplication.configurate(with: options);
        
        initTACAnalytics()
        
        AppTaskChecker.sharedInstance.start()
        
        refreshToken()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        initTACMessaging()
    }
    
    private func initTACMessaging() {
        TACMessagingService.default().token.bindTag("IDFA:\(TMMBeacon.shareInstance().deviceId()!)")
        TACMessagingService.default().token.bindTag("PLATFORM:ios")
        if let userInfo: DefaultsUser = Defaults[.user] {
            TACMessagingService.default().token.bindTag("USERID:\(userInfo.id ?? 0)")
            TACMessagingService.default().token.bindTag("COUNTRYCODE:\(userInfo.countryCode ?? 0)")
        }
    }
    
    private func initTACAnalytics() {
        var dict: [AnyHashable: Any] = ["platform":"ios"]
        if let userInfo: DefaultsUser = Defaults[.user] {
            dict["userId"] = userInfo.id
            dict["countryCode"] = userInfo.countryCode
        }
        let properties = TACAnalyticsProperties(dictionary: dict)
        TACAnalyticsService.setUserProperties(properties)
    }
    
    private func refreshToken() {
        if let accessToken: DefaultsAccessToken = Defaults[.accessToken] {
            if accessToken.expire.compare(Date().addingTimeInterval(-1 * 60 * 24)) == .orderedDescending {
                TMMAuthService.refreshToken(provider: authServiceProvider).then(in: .background, {token in
                    print("AccessToken refreshed!")
                }).catch(in: .background, { error in
                    print(error)
                })
            }
        }
    }
}

