//
//  AppDelegate.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import TMMSDK
import WebKit
import Moya
import SwiftyUserDefaults
import Siren
import SwiftRater

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var authServiceProvider = MoyaProvider<TMMAuthService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let tmmBeacon = TMMBeacon.initWithKey(TMMConfigs.TMMBeacon.key, secret: TMMConfigs.TMMBeacon.secret)
        tmmBeacon?.start()
        
        setupMTA()
        setupXG()
        
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
        
        let webView = UIWebView(frame: .zero)
        if let ua = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") {
            let newUserAgent = "\(ua) UCoin/\(AppBuildClosure())"
            print(newUserAgent)
            Defaults[.userAgent] = newUserAgent
            Defaults.synchronize()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        MTA.trackActiveEnd()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Siren.shared.checkVersion(checkType: .immediately)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MTA.trackActiveBegin()
        Siren.shared.checkVersion(checkType: .daily)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let token = XGPushTokenManager.default().deviceTokenString {
            savePushToken(token)
            if let userInfo: DefaultsUser = Defaults[.user] {
                XGPushTokenManager.default().bind(withIdentifier: "UserId:\(userInfo.id ?? 0)", type: .account)
                XGPushTokenManager.default().bind(withIdentifier: "CountryCode:\(userInfo.countryCode ?? 0)", type: .tag)
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
    }
    
    /**
     收到推送的回调
     @param application  UIApplication 实例
     @param userInfo 推送时指定的参数
     @param completionHandler 完成回调
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        XGPush.defaultManager().reportXGNotificationInfo(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    
    private func setupMTA() {
        #if DEBUG
        if let config = MTAConfig.getInstance() {
            config.debugEnable = true
        }
        #endif
        MTA.start(withAppkey: TMMConfigs.MTA.appKey)
        if let userInfo: DefaultsUser = Defaults[.user] {
            let account = MTAAccountInfo.init()
            account.type = MTAAccountTypeExt.custom
            account.account = "UserId:\(userInfo.id ?? 0)"
            account.accountStatus = MTAAccountStatus.normal
            let accountPhone = MTAAccountInfo.init()
            accountPhone.type = MTAAccountTypeExt.phone
            accountPhone.account = userInfo.mobile
            accountPhone.accountStatus = MTAAccountStatus.normal
            if userInfo.openId != "" {
                let openIdAccount = MTAAccountInfo.init()
                openIdAccount.type = MTAAccountTypeExt.weixin
                openIdAccount.account = userInfo.openId
                openIdAccount.accountStatus = MTAAccountStatus.normal
                MTA.reportAccountExt([account, accountPhone, openIdAccount])
            } else {
                MTA.reportAccountExt([account, accountPhone])
            }
            MTA.setUserProperty([TMMConfigs.UserPropertyName.creditLevel: String(userInfo.level)])
        }
    }
    
    private func setupXG() {
        XGPush.defaultManager().startXG(withAppID: TMMConfigs.XG.accessId, appKey: TMMConfigs.XG.accessKey, delegate: self)
        #if DEBUG
        XGPush.defaultManager().isEnableDebug = true
        #endif
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
    
    private func savePushToken(_ token: String) {
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        TMMDeviceService.savePushToken(idfa: deviceId, token: token, provider: deviceServiceProvider).then(in: .background, {token in
            print("Push Token saved!")
        }).catch(in: .background, { error in
            print(error)
        })
    }
}

extension AppDelegate: XGPushDelegate {
    
    // iOS 10 新增回调 API
    // App 用户点击通知
    // App 用户选择通知中的行为
    // App 用户在通知中心清除消息
    // 无论本地推送还是远程推送都会走这个回调
    func xgPush(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse?, withCompletionHandler completionHandler: @escaping () -> Void) {
        XGPush.defaultManager().reportXGNotificationResponse(response)
    }
    
    // App 在前台弹通知需要调用这个接口
    func xgPush(_ center: UNUserNotificationCenter, willPresent notification: UNNotification?, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let userInfo = notification?.request.content.userInfo {
            XGPush.defaultManager().reportXGNotificationInfo(userInfo)
        }
        completionHandler(UNNotificationPresentationOptions(rawValue: UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.sound.rawValue | UNNotificationPresentationOptions.alert.rawValue))
    }
    
    /**
     @brief 向信鸽服务器注册设备token的回调
     
     @param deviceToken 当前设备的token
     @param error 错误信息
     @note 当前的token已经注册过之后，将不会再调用此方法
     */
    
    func xgPushDidRegisteredDeviceToken(_ deviceToken: String?, error: Error?) {
        if let err = error {
            print(err.localizedDescription)
            return
        }
        if let token = deviceToken {
            savePushToken(token)
        }
    }
}
