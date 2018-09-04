//
//  NSString+Encryption.h
//  TMMSDK
//
//  Created by Syd on 2018/8/6.
//  Copyright © 2018年 tokenmama.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonHMAC.h>

/// 默认使用kCCOptionPKCS7Padding填充
#define kPaddingMode kCCOptionPKCS7Padding

@interface NSString (Encryption)

#pragma mark - DES加密

/*
 DES加密 key为NSString形式 结果返回base64编码
 */
- (NSString *)desEncryptWithKey:(NSString *)key;

/*
 DES加密 key为NSData形式 结果返回NSData
 */
- (NSData *)desEncryptWithDataKey:(NSData *)key;

#pragma mark - DES解密

/*
 DES解密，字符串必须为base64格式，key为字符串形式
 */
- (NSString *)desDecryptWithKey:(NSString *)key;

/*
 DES解密
 */
+ (NSData *)desDecryptWithData:(NSData *)data dataKey:(NSData *)key;

@end
