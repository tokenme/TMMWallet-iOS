//
//  QCloudSwizzing.h
//  AOPKit
//
//  Created by Dong Zhao on 2017/12/19.
//

#import <Foundation/Foundation.h>


/**
 swzzing一个类的两个方法

 @param class 将要被swizzing的类
 @param originalSelector 原始方法
 @param swizzledSelector 替换的方法
 */
FOUNDATION_EXTERN void QCloudeSwizzingClassMethod(Class cla, SEL originalSelector, SEL swizzledSelector);



/**
 获取实现了某个特定协议的所有的类

 @param protocol 需要实现的协议
 @return 实现了某个特定协议的所有的类
 */
FOUNDATION_EXTERN NSArray* QCloudClassesConformToProtocol(Protocol* protocol);
