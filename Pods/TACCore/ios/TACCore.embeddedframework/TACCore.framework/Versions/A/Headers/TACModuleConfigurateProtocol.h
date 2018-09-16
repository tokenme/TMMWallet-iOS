//
//  TACModuleConfigurateProtocol.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/9.
//

#import <Foundation/Foundation.h>

@class TACApplicationOptions;

/**
 模块配置接口，如果您实现了一个模块。对应的类可以通过实现该接口，来初始化相应的服务模块。
 */
@protocol TACModuleConfigurateProtocol <NSObject>

/**
 通过应用的配置文件来配置一个模块

 @param options 应用的全局配置信息
 @param error 用于传递错误信息的NSError对象指针
 @return 是否成功配置
 */
+ (BOOL) configurateModuleWithOptions:(TACApplicationOptions*)options error:(NSError* __autoreleasing*)error;


@optional
/**
 绑定一个特定的用户identifier

 @param identifier 用户的identifier
 */
+ (void) bindUserIdentifier:(NSString*)identifier;


/**
 设置全局统一的设备唯一标志

 @param deviceUUID 设备唯一标志
 */
+ (void) bindUnifiedDeviceUUID:(NSString*)deviceUUID;
/**
 设置开发模式

 @note 默认为RELEASE模式
 @param debug 开发模式：YES为DEBUG模式，NO为RELEASE模式。
 */
+ (void) setDebug:(BOOL)debug;

@end
