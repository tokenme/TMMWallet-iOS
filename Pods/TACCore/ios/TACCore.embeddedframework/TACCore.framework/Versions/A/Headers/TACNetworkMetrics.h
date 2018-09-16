//
//  TACNetworkMetrics.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/20.
//

#import <Foundation/Foundation.h>

/**
 网络监控的结果类型

 - TACNetworkMetricsResultTypeSuccess: 接口调用成功
 - TACNetworkMetricsResultTypeFail: 接口调用失败
 - TACNetworkMetricsResultTypeLogicFaild: 接口调用出现逻辑错误
 */
typedef NS_ENUM(NSUInteger, TACNetworkMetricsResultType) {
    TACNetworkMetricsResultTypeSuccess = 0,
    TACNetworkMetricsResultTypeFail = 1,
    TACNetworkMetricsResultTypeLogicFaild = 2,
};

@interface TACNetworkMetrics : NSObject
/**
 监控业务接口名
 */
@property (nonatomic, strong) NSString *interface;

/**
 上传请求包量，单位字节
 */
@property uint32_t requestPackageSize;

/**
 接收应答包量，单位字节
 */
@property uint32_t responsePackageSize;

/**
 消耗的时间，单位毫秒
 */
@property uint64_t consumedMilliseconds;

/**
 业务返回的应答码
 */
@property int32_t returnCode;

/**
 业务返回类型
 */
@property TACNetworkMetricsResultType resultType;

/**
 上报采样率，默认0含义为无采样
 */
@property uint32_t sampling;
@end
