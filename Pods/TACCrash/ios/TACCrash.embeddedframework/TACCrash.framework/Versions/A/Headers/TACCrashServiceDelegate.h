//
//  TACCrashServiceDelegate.h
//  AOPKit
//
//  Created by Dong Zhao on 2018/2/8.
//

#import <Foundation/Foundation.h>

@class TACCrashService;
@protocol TACCrashServiceDelegate <NSObject>
@optional
/**
 当放生异常的时候，需要附带上的环境信息。您可以通过该接口提供更多的信息以辅助您定位问题。

 @param service 当前的Crash服务实例
 @param exception 异常信息
 */
- (NSString*) crashService:(TACCrashService*)service  attachmentForException:(NSException*)exception;
@end
