//
//  TACApplicationOptions.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/9.
//

#import <Foundation/Foundation.h>
#import "TACBaseOptions.h"
#import "TACProjectOptions.h"
#import "TACSetupApplicationOptions.h"
/**
 当前程序对应的服务的全局配置信息
 */
@interface TACApplicationOptions : TACBaseOptions

@property (nonatomic, readonly, strong) TACProjectOptions* project;

@property (nonatomic, readonly, strong) TACSetupApplicationOptions* application;

- (instancetype) init NS_UNAVAILABLE;
/**
 当前配置信息的版本号
 */
@property (nonatomic, readonly, strong) NSString* version;


/**
 各个服务的配置信息，通过KeyValue的形式存储在字典中
 */
@property (nonatomic, readonly, strong) NSDictionary* services;


/**
 默认的程序服务配置信息

 @return TACApplicationOptions对象实例
 */
+ (TACApplicationOptions*) defaultApplicationOptions;

@end
