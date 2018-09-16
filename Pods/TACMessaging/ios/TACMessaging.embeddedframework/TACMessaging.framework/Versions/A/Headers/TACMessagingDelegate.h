//
//  TACMessagingDelegate.h
//  TACMessaging
//
//  Created by Dong Zhao on 2017/11/20.
//

#import <Foundation/Foundation.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@protocol TACMessagingDelegate <NSObject>
@optional


/**
 @brief 监控推送服务地启动情况
 
 @param isSuccess 推送是否启动成功
 @param error 推送启动错误的信息
 */
- (void) messagingDidFinishStart:(BOOL)isSuccess error:(nullable NSError *)error;

/**
 @brief 监控服务的终止情况
 
 @param isSuccess 推送是否终止
 @param error 推动终止错误的信息
 */
- (void) messagingDidFinishStop:(BOOL)isSuccess error:(nullable NSError *)error;


/**
 @brief 监控服务上报推送消息的情况
 
 @param isSuccess 上报是否成功
 @param error 上报失败的信息
 */
- (void) messagingDidReportNotification:(BOOL)isSuccess error:(nullable NSError *)error;


#pragma mark iOS10 以上有效

@optional

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __TVOS_PROHIBITED;


/**
 处理iOS 10 UNUserNotification.framework的对应的方法
 
 @param center [UNUserNotificationCenter currentNotificationCenter]
 @param notification 通知对象
 @param completionHandler 回调对象，必须调用
 */
- (void) messagingUserNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nullable UNNotification *)notification withCompletionHandler:(nonnull void (^)(UNNotificationPresentationOptions options))completionHandler __IOS_AVAILABLE(10.0) DEPRECATED_MSG_ATTRIBUTE("Deprecated!!! please use UNUserNotificationCenterDelegate");


/**
 处理iOS 10 UNUserNotification.framework的对应的方法
 
 @param center [UNUserNotificationCenter currentNotificationCenter]
 @param response 用户对通知消息的响应对象
 @param completionHandler 回调对象，必须调用
 */
- (void)messagingUserNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nullable UNNotificationResponse *)response withCompletionHandler:(nonnull void (^)(void))completionHandler __IOS_AVAILABLE(10.0) DEPRECATED_MSG_ATTRIBUTE("Deprecated!!! please use UNUserNotificationCenterDelegate");

#endif
@end
