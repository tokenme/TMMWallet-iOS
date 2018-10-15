//
//  TACAnalyticsEvent.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/17.
//

#import <Foundation/Foundation.h>
#import "TACAnalyticsProperties.h"


/**
 标志一个统计的事件。他们的唯一标记为identifier或者（identifier+properties）。您可以通过创建该对象，来创建一个事件的追踪标记。并在TACAnalyticsService使用该对象，进行操作。
 */
@interface TACAnalyticsEvent : NSObject

/**
 事件的名称
 */
@property (nonatomic, readonly, strong) NSString* identifier;

/**
 事件的属性，只有在控制台中事先配置好才会生效。
 */
@property (nonatomic, readonly, strong) TACAnalyticsProperties* properties ;
+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;


/**
 通过identifier创建一个事件的追踪标记

 @param identifer 事件名称
 @see eventWithIdentifier:properties:
 @return TACAnalyticsEvent实例
 */
+ (TACAnalyticsEvent*) eventWithIdentifier:(NSString*)identifer;


/**
 通过事件名称和事件属性来初始化一个TACAnalyticsEvent对象的实例。

 @see eventWithIdentifier:
 
 @param identifer 事件名称，不可为nil，如果为nil则会直接报错。
 @param properties 事件属性，只有在控制台中事先配置好才会生效。不可为nil，如果为nil直接报错。
 @return    TACAnalyticsEvent实例
 */
+ (TACAnalyticsEvent*) eventWithIdentifier:(NSString *)identifer properties:(TACAnalyticsProperties*)properties;
@end
