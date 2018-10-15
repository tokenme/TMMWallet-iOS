//
//  TACAnalyticsStrategy.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/20.
//

#import <Foundation/Foundation.h>

/**
 Analytics数据上报策略,您只能选择一种上报策略，不可叠加使用

 - TACAnalyticsStrategyInstant: 实时上报
 - TACAnalyticsStrategyBatch: 批量上报，达到缓存临界值时触发发送
 - TACAnalyticsStrategyLaunch: 应用启动时发送
 - TACAnalyticsStrategyOnlyWifi: 仅在WIFI网络下发送
 - TACAnalyticsStrategyPeriod: 每间隔一定最小时间发送，默认24小时
 - TACAnalyticsStrategyDeveloper: 开发者在代码中主动调用发送行为
 - TACAnalyticsStrategyOnlyWifiWithoutCache: 仅在WIFI网络下发送, 发送失败以及非WIFI网络情况下不缓存数据
 - TACAnalyticsStrategyBatchPeriodWithoutCache: 不缓存数据，批量上报+间隔上报组合。适用于上报特别频繁的场景。
 */
typedef NS_ENUM(NSUInteger, TACAnalyticsStrategy) {
    TACAnalyticsStrategyInstant = 1,
    TACAnalyticsStrategyBatch = 2,
    TACAnalyticsStrategyLaunch = 3,
    TACAnalyticsStrategyOnlyWifi = 4,
    TACAnalyticsStrategyPeriod = 5,
    TACAnalyticsStrategyDeveloper = 6,
    TACAnalyticsStrategyOnlyWifiWithoutCache = 7,
    TACAnalyticsStrategyBatchPeriodWithoutCache = 8,
};
