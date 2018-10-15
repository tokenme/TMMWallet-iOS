//
//  TACPayEvent.h
//  AOPKit
//
//  Created by karisli(李雪) on 2018/4/8.
//

#import <Foundation/Foundation.h>
#import "ADTracker.h"
@interface TACPayEvent : NSObject

/**
 货币种类，支持两种：人民币、美金
 */
@property (nonatomic,assign) TACMTAADPayMoneyType currenceType;


/**
 订单ID， 或交易流水号
 */
@property (nonatomic,strong) NSString * orderID;

/**
 订单金额
 */
@property (nonatomic,assign) double moneyAmount;


/**
 支付类型，如微信、支付宝、银联等
 */
@property (nonatomic,strong) NSString *payChannel;
@end
