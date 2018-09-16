//
//  TACAnalyticsProperties.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/17.
//

#import <Foundation/Foundation.h>

/**
 事件的属性，只有在控制台中事先配置好才会生效。
 */
@interface TACAnalyticsProperties : NSDictionary

@property (nonatomic, strong, readonly) NSDictionary* properties;
+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;


/**
 通过字典的形式创建一个TACAnalyticsProperties对象的实例

 @param properties 事件的属性内容
 @return TACAnalyticsProperties实例
 */
+ (instancetype) propertiesWithDictionary:(NSDictionary*)properties;

@end
