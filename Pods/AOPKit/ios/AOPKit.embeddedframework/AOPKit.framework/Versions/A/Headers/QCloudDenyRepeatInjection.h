//
//  QCloudDenyRepeatInjection.h
//  Pods
//
//  Created by stonedong on 8/17/16.
//
//

#import <UIKit/UIKit.h>

/**
 用来承载防止重复点击逻辑的核心容器
 */
@interface QCloudDenyRepeatInjection : UIControl
@property (nonatomic, assign) float denyRepeatTime;
@end


/**
 对一个UIControl的实例，注入防止重复点击的逻辑

 @param object 一个UIControl的实例
 @param denyTime 防止重复点击的时间，比如0.5s,单位为s
 @return 已经注入了重复点击逻辑的UIControl的实例
 */
QCloudDenyRepeatInjection* QCloudInjectiondenyRepeatLogic(UIControl* object, float denyTime);
