//
//  TACCrashService.h
//  TACCrash
//
//  Created by Dong Zhao on 2017/11/17.
//

#import <Foundation/Foundation.h>
#import "TACCrashServiceDelegate.h"

/**
 崩溃检测服务全局接口
 */
@interface TACCrashService : NSObject

/**
 Crash服务的委托者，提供更多信息来辅助定位问题
 */
@property (nonatomic, weak) id<TACCrashServiceDelegate> delegate;


/**
 设置用户的场景信息
 */
@property (nonatomic, assign) NSUInteger userSenceTag;
/**
 默认的崩溃检测服务

 @return 默认的崩溃检测服务
 */
+ (TACCrashService*) shareService;


/**
 设置关键数据，随崩溃信息上报
 @param value 内容
 @param key 关键字
 */
- (void) setUserValue:(NSString*)value forKey:(NSString*)key;


/**
 *  获取关键数据
 *
 *  @return 关键数据
 */
- (NSDictionary * )allUserValues;
/**
 上报异常信息

 @param exception 异常
 */
- (void) reportException:(NSException*)exception;


/**
 *    @brief 上报自定义错误
 *
 *    @param category    类型(Cocoa=3,CSharp=4,JS=5,Lua=6)
 *    @param aName       名称
 *    @param aReason     错误原因
 *    @param aStackArray 堆栈
 *    @param info        附加数据
 *    @param terminate   上报后是否退出应用进程
 */
- (void)reportExceptionWithCategory:(NSUInteger)category name:(NSString *)aName reason:(NSString *)aReason callStack:(NSArray *)aStackArray extraInfo:(NSDictionary *)info terminateApp:(BOOL)terminate;


/**
 上报一个错误

 @param error 错误信息
 */
- (void) reportError:(NSError*)error;


/**
 *  App 是否发生了连续闪退
 *  如果启动SDK 且 5秒内 闪退，且次数达到 3次 则判定为连续闪退
 *
 *  @return 是否连续闪退
 */
- (BOOL)isAppCrashedOnStartUpExceedTheLimit;

@end
