//
//  TACCrashOptions.h
//  TACCrash
//
//  Created by Dong Zhao on 2017/11/17.
//

#import <TACCore/TACCore.h>
#import "TACCrashServiceDelegate.h"
/**
 崩溃检测模块的配置信息
 */
@interface TACCrashOptions : TACBaseOptions

/**
 当前崩溃检测服务对应的APPID
 */
@property (nonatomic, strong) NSString* appId;


/**
 *  崩溃数据过滤器，如果崩溃堆栈的模块名包含过滤器中设置的关键字，则崩溃数据不会进行上报
 *  例如，过滤崩溃堆栈中包含搜狗输入法的数据，可以添加过滤器关键字SogouInputIPhone.dylib等
 */
@property (nonatomic, strong) NSArray<NSString*>* excludeModuleFilters;



/**
 该服务是否启动，如果您引入了多个崩溃检测服务，可能不希望启动该模块，请在程序中设置为NO。默认为YES。
 */
@property (nonatomic, assign) BOOL enable;

/**
 *  设置自定义渠道标识
 */
@property (nonatomic, copy) NSString *channel;

/**
 *  设置自定义版本号
 */
@property (nonatomic, copy) NSString *version;

/**
 *  设置自定义设备唯一标识
 */
@property (nonatomic, copy) NSString *deviceIdentifier;

/**
 *  卡顿监控开关，默认关闭
 */
@property (nonatomic) BOOL blockMonitorEnable;

/**
 *  卡顿监控判断间隔，单位为秒
 */
@property (nonatomic) NSTimeInterval blockMonitorTimeout;

/**
 *  设置 App Groups Id (如有使用 Bugly iOS Extension SDK，请设置该值)
 */
@property (nonatomic, copy) NSString *applicationGroupIdentifier;

/**
 *  进程内还原开关，默认开启
 */
@property (nonatomic) BOOL symbolicateInProcessEnable;

/**
 *  非正常退出事件记录开关，默认关闭
 */
@property (nonatomic) BOOL unexpectedTerminatingDetectionEnable;

/**
 *  页面信息记录开关，默认开启
 */
@property (nonatomic) BOOL viewControllerTrackingEnable;

/**
 *  崩溃数据过滤器，如果崩溃堆栈的模块名包含过滤器中设置的关键字，则崩溃数据不会进行上报
 *  例如，过滤崩溃堆栈中包含搜狗输入法的数据，可以添加过滤器关键字SogouInputIPhone.dylib等
 */
@property (nonatomic, copy) NSArray *excludeModuleFilter;


/**
 * 控制台日志上报开关，默认开启，如果您开启了该功能。您使用 TACLog 输出的日志，会增加一份输出到 Bugly 的日志上报中。这里的日志，您可以理解为是当前Crash的一个环境上下文。可以更好的帮助您定位问题。建议您使用 TACLogger 进行日志输出。
 
 @note default is YES
 */
@property (nonatomic, assign) BOOL consolelogEnable;
@end


@interface TACApplicationOptions (Crash)

/**
 默认的崩溃检测服务的配置信息
 */
@property (nonatomic, strong, readonly) TACCrashOptions* crashOptions;
@end
