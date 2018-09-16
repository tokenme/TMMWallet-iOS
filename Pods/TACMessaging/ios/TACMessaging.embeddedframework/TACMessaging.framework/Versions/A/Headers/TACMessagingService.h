//
//  TACMessagingService.h
//  TACMessaging
//
//  Created by Dong Zhao on 2017/11/15.
//

#import <Foundation/Foundation.h>

#import "TACMessagingDelegate.h"

@class TACMessagingDeviceToken;
@interface TACMessagingService : NSObject


/**
 TACMessagingService各种状态变更通知和回调
 */
@property (nonatomic, weak) NSObject<TACMessagingDelegate>* delegate;


/**
  @brief 返回信鸽推送服务的状态，启动返回YES，未启动返回NO。
 */
@property (nonatomic, assign, readonly) BOOL status;

/**
 @brief 管理应用角标
 您可以通过该接口：
 1. 获取当前应用在SpringBoard上面显示的角标数量
 2. 设置当前应用在SpringBoard上面显示的角标数量
 */
@property (nonatomic, assign) NSInteger applicationBadgeNumber;


/**
 当前设备的deviceToken，如果在推送服务没有准备就绪的情况下，将返回nil。准备就绪后为当前设备的deviceToken。您可以通过该对象，来对token进行相关操作，例如：绑定identifier等。您一般需要在函数中 `application:didRegisterForRemoteNotificationsWithDeviceToken:` 中或者该函数调用之后，再获取本 token 。
 */
@property (nonatomic, strong, readonly) TACMessagingDeviceToken* token;

+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;


/**
 推送服务对外提供服务的单例入口

 @return 推送服务对外提供服务的单例入口
 */
+ (TACMessagingService*) defaultService;

/**
 启动推送服务，默认自动启动，如果您关掉推送之后，可以使用该接口来打开
 */
- (void) startReceiveNotifications;
/**
 @brief 停止信鸽推送服务
 @note 调用此方法将导致当前设备不再接受信鸽服务推送的消息.如果再次需要接收信鸽服务的消息推送，则必须需要再次调用startXG:withAppKey:delegate:方法重启信鸽推送服务
 */
- (void) stopReceiveNotifications;

/**
 @brief 上报应用收到的推送信息，以便信鸽服务能够统计相关数据，包括但不限于：1.推送消息被点击的次数，2.消息曝光的次数
 
 @param metrics 应用接收到的推送消息对象的内容
 
 @note 您已经不需要调用该功能，我们已经通过LogicInjection的方式帮您实现，具体实现策略可以查看 AOPKit
 @note 请在实现application delegate 的 application:didFinishLaunchingWithOptions:或者application:didReceiveRemoteNotification:的方法中调用此接口，参数就使用这两个方法中的NSDictionaryl类型的参数即可，从而完成推送消息的数据统计
 */
- (void) reportNotificationMetrics:(nonnull NSDictionary*)metrics;


/**
 @brief 查询设备通知权限是否被用户允许
 
 @param handler 查询结果的返回方法
 @note iOS 10 or later 回调是异步地执行
 */
- (void)deviceNotificationIsAllowed:(nonnull void (^)(BOOL isAllowed))handler;




/**
 上报地理位置信息，后续可以使用针对位置进行精准推送
 
 @param latitude 维度
 @param longitude 经度
 */
- (void)reportLocationWithLatitude:(double)latitude longitude:(double)longitude;



/**
 上报 App 角标数到信鸽服务器
 @note  此接口是为了实现角标+1的功能，服务器会在这个数值基础上进行角标数新增的操作，调用成功之后，会覆盖之前值
 @param badgeNumber App 角标数
 */
- (void) reportLocalBadgeNumber:(NSInteger)badgeNumber;


@end

