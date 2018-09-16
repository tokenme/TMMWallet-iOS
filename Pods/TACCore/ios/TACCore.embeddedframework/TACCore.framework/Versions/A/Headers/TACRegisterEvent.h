//
//  TACRegisterEvent.h
//  AOPKit
//
//  Created by karisli(李雪) on 2018/4/8.
//

#import <Foundation/Foundation.h>
#import "ADTracker.h"
@interface TACRegisterEvent : NSObject


/**
 账号类型
 */
@property (nonatomic,assign) TACMTAADAccountType accountType;


/**
 具体的账号
 */
@property (nonatomic,strong) NSString *userName;
@end
