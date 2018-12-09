//
//  TXCommonUtils.h
//  authsdk
//
//  Created by yangli on 12/03/2018.
//  Copyright © 2018 alicom. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TX_Auth_Result_Success      @"6666"
#define TX_Auth_Result_TimeOut      @"5555"
#define TX_Auth_Result_Fail         @"4444"
#define TX_Auth_Result_No_SIM_Card  @"1111"
#define TX_Auth_Result_No_Network   @"2222"
#define TX_Auth_Result_Other_Err    @"3333"

@interface TXCommonUtils : NSObject

/*
 * 判断设备是否是中国联通，【注】此接口在苹果双卡双待iPhone XS Max上，双卡，且背卡槽开移动网络时判断不准确，不可使用！！
 */
+ (BOOL)isChinaUnicom;

/*
 * 判断设备是否是中国移动，【注】此接口在苹果双卡双待iPhone XS Max上，双卡，且背卡槽开移动网络时判断不准确，不可使用！！
 */
+ (BOOL)isChinaMobile;

/*
 * 判断设备是否是中国电信，【注】此接口在苹果双卡双待iPhone XS Max上，双卡，且背卡槽开移动网络时判断不准确，不可使用！！
 */
+ (BOOL)isChinaTelecom;

/*
 * 获取设备运营商类型，【注】此接口在苹果双卡双待iPhone XS Max上，双卡且背卡槽开移动网络时判断不准确，不可使用！！
 */
+ (NSString *)getCurrentMobileNetworkName;

/*
 * 判断设备运营商名称，【注】此接口在苹果双卡双待iPhone XS Max上，双卡且背卡槽开移动网络时判断不准确，不可使用！！
 */
+ (NSString *)getCurrentCarrierkName;

+ (NSString *)getNetworktype;
+ (BOOL)simSupportedIsOK;

/**
 判断wwan是否开着（通过p0网卡判断，无wifi或有wifi情况下都能检测到）
 @return 结果
 */
+ (BOOL)isWWANOpen;

/**
 判断wwan是否开着（仅无wifi情况下）
 @return 结果
 */
+ (BOOL)reachableViaWWAN;

@end
