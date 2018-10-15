//
//  TACLogger.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/21.
//

#import <Foundation/Foundation.h>
#import <QCloudCore/QCloudCore.h>

/*
 TAC 的日志功能是基于QCloudLogger扩展而来，您可以通过配置环境 QCloudLogger 相关配置来改变日志的行为。整个 TAC 与 QCloudCore 共享同一日志框架。
 需要着重说明的是日志的打印级别在 QCloudLogger 中统一设置。
 */

#define TACLogError(frmt, ...) \
QCloudLogError(frmt, ##__VA_ARGS__)

#define TACLogWarning(frmt, ...) \
QCloudLogWarning(frmt, ##__VA_ARGS__)

#define TACLogInfo(frmt, ...) \
QCloudLogInfo(frmt, ##__VA_ARGS__)

#define TACLogDebug( frmt, ...) \
QCloudLogDebug(frmt, ##__VA_ARGS__)

#define TACLogVerbose(frmt, ...) \
QCloudLogVerbose(frmt, ##__VA_ARGS__)

#define TACLogException(exception) \
QCloudLogException(exception)

#define TACLogTrance()\
QCloudLogTrance()

