//
//  installtracker.h
//  installtracker
//
//  Created by xiang on 20/06/2017.
//  Copyright © 2017 xiangchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//帐号的类别
typedef NS_ENUM(NSInteger, TACMTAADAccountType) {
	TACADAccountMobile, //手机号
	TACADAccountMail,   //邮箱
	TACADAccountWX,	 //微信
	TACADAccountQQ,	 //QQ
	TACADAccountOther   //其它
};

//货币种类
typedef NS_ENUM(NSInteger, TACMTAADPayMoneyType) {
	TACADPayCNY, //人民币
	TACADPayUSD  //美金
};

@interface TACADTracker : NSObject

+ (instancetype)getInstance;

#pragma mark - 激活后的活跃事件

/**
 帐号注册事件
 
 @param accountType 帐号类型
 @param account 具体的帐号
 */
- (void)trackRegAccountEvent:(TACMTAADAccountType)accountType account:(NSString *)account;

/**
 付费事件
 
 @param moneyType 货币种类，支持两种：人民币、美金
 @param orderID 订单ID， 或交易流水号
 @param payNum 订单金额
 @param payType 支付类型，如微信、支付宝、银联等
 */
- (void)trackUserPayEvent:(TACMTAADPayMoneyType)moneyType orderID:(NSString *)orderID
				   payNum:(double)payNum
				  payType:(NSString *)payType;

#pragma mark - 有落地页，需要和JS SDK进行交互

//处理Url Schema
- (void)handleOpenURL:(NSURL *)url;

/**
 在启动的第一个页面初始化
 
 @param ifNeedCookie 是否启用cookie。如果和App的UI结构冲突，出现黑屏问题时，请传NO
 */
- (void)startByViewDidload:(BOOL)ifNeedCookie;

#pragma mark - 过期的方法

//判断是否是TACMTA来源
-(BOOL)checkIsFromMTARefer:(NSUserActivity *)userActivity DEPRECATED_ATTRIBUTE;

//设置中间页的地址,例如投放的地址(如果是通过接入js sdk自定义的话，需要调用此接口)
//示例: http://domain.com/test/download.html
-(void)setChannelUrl:(NSString *)urlString  DEPRECATED_ATTRIBUTE;


@end
