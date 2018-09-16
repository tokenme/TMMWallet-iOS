//
//  TACApplication.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/9.
//

#import <Foundation/Foundation.h>

@class TACApplicationOptions;

/**
 承载TAC全局能力入口的对象。该对象为单例，您可以通过单例来获取该对象的能力。在TAC的配置上，我们采用两部式初始化。application的初始化依赖TACApplicationOptions对象的实例，如果您没有自定义任何配置的需求。
 */
@interface TACApplication : NSObject

/**
 应用的全局配置信息
 */
@property (nonatomic, strong, readonly) TACApplicationOptions* options;


/**
 设备唯一ID
 */
@property (nonatomic, strong, readonly) NSString* deviceUUID;

/**
 对默认的应用进行配置，配置信息会从tac_services_configurations.json文件中读取。
 */
+ (void) configurate;


/**
 使用指定的Options对默认的应用进行配置，配置信息会从tac_services_configurations.json文件中读取。

 @param options 程序配置
 */
+ (void) configurateWithOptions:(TACApplicationOptions*)options;

/**
 @return 返回默认的应用，如果没有默认的应用则返回nil。
 */

+ (TACApplication*) defaultApplication;
/**
 通过应用的全局配置信息初始化一个应用的实例

 @param options 应用的全局配置信息
 @return 应用的实例
 */
- (instancetype) initWithOptions:(TACApplicationOptions*)options;



/**
 绑定用户的唯一标识，用户串联起来该用户在不同系统中的行为。

 @note 请在用户登陆之后，调用该接口设置
 @param userIdentifier 用户唯一标识
 */
- (void) bindUserIdentifier:(NSString*)userIdentifier;

@end
