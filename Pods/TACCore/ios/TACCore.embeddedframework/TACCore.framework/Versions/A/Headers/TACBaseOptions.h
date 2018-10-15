//
//  TACBaseOptions.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/15.
//

#import <Foundation/Foundation.h>


/**
 所有配置信息的基类，增加合法性校验接口
 */
@interface TACBaseOptions : NSObject
+ (instancetype) new NS_UNAVAILABLE;
/**
 @return  检查当前的配置文件是否合法，如果不合法，直接返回错误（NO）。如果合法，则返回YES。
 */
- (BOOL) vaild:(NSError* __autoreleasing*)error;
@end
