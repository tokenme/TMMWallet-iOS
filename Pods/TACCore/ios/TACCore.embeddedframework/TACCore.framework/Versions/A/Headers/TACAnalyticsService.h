//
//  TACAnalyticsService.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/15.
//

#import <Foundation/Foundation.h>
#import "TACAnalyticsProperties.h"
#import "TACNetworkMetrics.h"
#import "ADTracker.h"
#import "MTAHybrid.h"
@class TACRegisterEvent;
@class TACPayEvent;
@class TACAnalyticsEvent;
/**
 提供事件追踪的基础服务，
 */
@interface TACAnalyticsService : NSObject
#pragma mark 追踪页面访问
/**
 @brief 标记一次页面访问的开始。此接口需要跟trackPageDisappear配对使用
 
 @note 多次开始以第一次开始的时间为准
 @see trackPageDisappear:
 @param identifer 将要追踪的页面的名称
 */
+ (void) trackPageAppear:(NSString*)identifer;
/**
 @brief 标记一次页面访问的结束，此接口需要跟trackPageAppear配对使用
 
 @note 多次结束以第一次结束的时间为准
 @see trackPageAppear:
 @param identifer 将要追踪的页面的名称
 */
+ (void) trackPageDisappear:(NSString*)identifer;
#pragma mark 追踪自定义事件
/**
 @brief 上传自定义事件
 提供可自定义配置的用户行为事件、业务计算事件统计，打造与业务场景深度结合的统计分析。
 @warning 事件的参数，参数需要先在MTA前台配置好才能生效
 @param event 进行上报的事件，不可以为nil。当传入nil的时候，在调试阶段会直接报错。
 */
+ (void) trackEvent:(TACAnalyticsEvent*)event;
#pragma mark 统计时长
/**
 @brief **开始**统计一个事件的时长
 
 **开始**统计一个事件的时长。该接口将会标记一个事件已经开始。并等待事件结束的消息。
 @warning 事件的参数，参数需要先在MTA前台配置好才能生效
 @param event 进行上报的事件，不可以为nil。当传入nil的时候，在调试阶段会直接报错。
 */
+ (void) trackEventDurationBegin:(TACAnalyticsEvent*)event;
/**
 @brief **结束**统计一个事件的时长
 
 **结束**统计一个事件的时长。该接口将会标记一个事件已经结束。如果您打开了实时传输特性，将会立刻进行上报。如果没有打开，则会将该记录写入缓存，等待合适的时机进行上传。
 
 @warning 事件的参数，参数需要先在MTA前台配置好才能生效
 @see trackEventDurationBegin:

 @param event 进行上报的事件，不可以为nil。当传入nil的时候，在调试阶段会直接报错。
 */
+ (void) trackEventDurationEnd:(TACAnalyticsEvent*)event;
/**
 @brief 直接记录一个事件的时长
 @warning 事件的参数，参数需要先在MTA前台配置好才能生效

 @param event 进行上报的事件，不可以为nil。当传入nil的时候，在调试阶段会直接报错。
 */
+ (void) trackEvent:(TACAnalyticsEvent*)event duration:(float)duration;



#pragma mark 网络配置


/**
 监控自有的网络状况，您可以通过创建TACNetworkMetrics来监控网络的状况。

 @param metrics 网络状况。
 */
+ (void) trackNetworkMetrics:(TACNetworkMetrics*)metrics;


#pragma mark 配置

/**
 检测session是否过期，若过期，则生成一个新Session事件
 事件上报方式按照全局上报方式上报
 */

+ (void) exchangeNewSession;

/**
 用户分群: 支持用户自定义属性
 
 @param kvs key-value形式，例如"画像属性1", "属性值1"
 */
+ (void)  setUserProperties:(TACAnalyticsProperties *)kvs;

/**
 激活后的活跃事件的上报, 请在主线程中调用
 
 注册事件 通过上报付费事件，您可以统计到每一次投放的注册转换率等标准监测指标，也能向渠道回传以获得广告投放优化
 
 @param regEvent 不可以为空
 */

+(void)  trackRegisterAccountEvent:(TACRegisterEvent *)regEvent;

/**
 激活后的活跃事件的上报, 请在主线程中调用

 付费事件 通过上报付费事件，您可以统计到每一次投放的注册转换率等标准监测指标，也能向渠道回传以获得广告投放优化

 @param payEvent 不可以为空
 */
+ (void)  trackUserPayEvent:(TACPayEvent *)payEvent ;


/**
 开始捕获一个WebView的异常

 @param webview 需要捕获异常的WebView
 */
+ (void)  catchExceptionForUIWebView:(UIWebView*)webview;

/**
 开始捕获一个WebView的异常

 @param wkWebview 需要捕获异常的WebView
 */
+ (void)  catchExceptionForWKWebView:(WKWebView*)wkWebview;


#pragma 废弃的API

/**
 已经废弃的API，用来设置用户属性
 
 @see setUserProperties:
 @param kvs 用户属性
 */
+ (void)  setUserProperty:(NSDictionary *)kvs NS_DEPRECATED_IOS(1_0_0,1_0_0,"setUserProperties:") ;

@end
