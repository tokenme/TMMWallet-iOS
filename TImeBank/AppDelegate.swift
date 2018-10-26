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
import Siren
import SwiftRater

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options:[.badge, .sound, .alert]) {_,_ in
        }
        
        let tmmBeacon = TMMBeacon.initWithKey(TMMConfigs.TMMBeacon.key, secret: TMMConfigs.TMMBeacon.secret)
        tmmBeacon?.start()
        let options = TACApplicationOptions.default()
        options?.analyticsOptions.idfa = tmmBeacon?.deviceId()
        options?.messagingOptions.autoStart = true
        TACApplication.configurate(with: options);
        initTACAnalytics()
        
        AppTaskChecker.sharedInstance.start()
        
        refreshToken()
        
        Siren.shared.checkVersion(checkType: .immediately)
        
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.usesUntilPrompt = 10
        SwiftRater.significantUsesUntilPrompt = 3
        SwiftRater.daysBeforeReminding = 1
        SwiftRater.showLaterButton = true
        SwiftRater.debugMode = false
        SwiftRater.appLaunched()
        
        setupShareSDK()
        
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
        Siren.shared.checkVersion(checkType: .immediately)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Siren.shared.checkVersion(checkType: .daily)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        initTACMessaging()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .alert])
    }
    
    private func initTACMessaging() {
        if let userInfo: DefaultsUser = Defaults[.user] {
            TACApplication.default()?.bindUserIdentifier("UserId:\(userInfo.id ?? 0)")
            TACMessagingService.default().token.bindTag("Country:\(userInfo.countryCode ?? 0)")
            savePushToken(token: TACMessagingService.default().token.deviceTokenString)
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
            if accessToken.expire.compare(Date().addingTimeInterval(60 * 24)) == .orderedAscending {
                TMMAuthService.refreshToken(provider: authServiceProvider).then(in: .background, {token in
                    print("AccessToken refreshed!")
                }).catch(in: .background, { error in
                    print(error)
                })
            }
        }
    }
    
    private func setupShareSDK() {
        ShareSDK.registPlatforms { (ssdkRegister: SSDKRegister?) in
            guard let register = ssdkRegister else { return }
            register.setupSinaWeibo(withAppkey: TMMConfigs.Weibo.appID, appSecret: TMMConfigs.Weibo.appKey, redirectUrl: TMMConfigs.Weibo.redirectURL)
            register.setupQQ(withAppId: TMMConfigs.QQ.appID, appkey: TMMConfigs.QQ.appKey)
            register.setupWeChat(withAppId: TMMConfigs.WeChat.appID, appSecret: TMMConfigs.WeChat.appKey)
            register.setupTwitter(withKey: TMMConfigs.Twitter.key, secret: TMMConfigs.Twitter.secret, redirectUrl: TMMConfigs.Twitter.redirectURL)
            register.setupFacebook(withAppkey: TMMConfigs.Facebook.key, appSecret: TMMConfigs.Facebook.secret, displayName: TMMConfigs.Facebook.displayName)
            register.setupTelegram(byBotToken: TMMConfigs.Telegram.botToken, botDomain: TMMConfigs.Telegram.domain)
            register.setupLineAuthType(SSDKAuthorizeType.SSO)
            }
    }
    
    private func savePushToken(token: String) {
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        TMMDeviceService.savePushToken(idfa: deviceId, token: token, provider: deviceServiceProvider).then(in: .background, {token in
            print("Push Token saved!")
        }).catch(in: .background, { error in
            print(error)
        })
    }
}

