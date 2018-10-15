//
//  TACMessagingOptions.h
//  TACMessaging
//
//  Created by Dong Zhao on 2017/11/15.
//

#import <TACCore/TACCore.h>


/**
 推送模块的配置信息
 */
@interface TACMessagingOptions : TACBaseOptions

/**
 推送模块的服务标志
 */
@property (nonatomic, assign) uint32_t appId;

/**
 推送模块的服务Key
 */
@property (nonatomic, strong) NSString* appKey;


/**
 是否默认启动推送服务，默认为YES
 */
@property (nonatomic, assign) BOOL autoStart;
@end


@interface TACApplicationOptions (Messaging)
/**
 推送模块的配置信息
 */
@property (nonatomic, strong, readonly) TACMessagingOptions* messagingOptions;
@end
