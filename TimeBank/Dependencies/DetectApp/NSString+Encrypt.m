//
//  NSString+Encryption.m
//  TMMSDK
//
//  Created by Syd on 2018/8/6.
//  Copyright © 2018年 tokenmama.io. All rights reserved.
//

#import "NSString+Encrypt.h"
#import "NSData+Base64.h"

@implementation NSString (Encryption)

#pragma mark - DES加密

/*
 DES加密 key为NSString形式 结果返回base64编码
 */
- (NSString *)desEncryptWithKey:(NSString *)key {
    NSData *desKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *resultData = [self desEncryptWithDataKey:desKey];
    return [resultData base64EncodedString];
}

/*
 DES加密 key为NSData形式 结果返回NSData
 */
- (NSData *)desEncryptWithDataKey:(NSData *)key {
    return [self desEncryptOrDecrypt:kCCEncrypt data:[self dataUsingEncoding:NSUTF8StringEncoding] dataKey:key mode:kPaddingMode | kCCOptionECBMode];
}

#pragma mark - DES解密

- (NSString *)desDecryptWithKey:(NSString *)key {
    NSData *desKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    NSData *resultData = [NSString desDecryptWithData:data dataKey:desKey];
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

+ (NSData *)desDecryptWithData:(NSData *)data dataKey:(NSData *)key {
    return [[NSString alloc] desEncryptOrDecrypt:kCCDecrypt data:data dataKey:key mode:kPaddingMode | kCCOptionECBMode];
}

- (NSData *)desEncryptOrDecrypt:(CCOperation)option data:(NSData *)data dataKey:(NSData *)key mode:(int)mode{
    //    if ([key length] != 16 && [key length] != 24 && [key length] != 32 ) {
    //        @throw [NSException exceptionWithName:@"Encrypt"
    //                                       reason:@"Length of key is wrong. Length of iv should be 16, 24 or 32(128, 192 or 256bits)"
    //                                     userInfo:nil];
    //    }
    
    // setup output buffer
    size_t bufferSize = [data length] + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    
    // do encrypt
    size_t encryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(option,
                                          kCCAlgorithmDES,
                                          mode,
                                          [key bytes],     // Key
                                          kCCKeySizeDES,    // kCCKeySizeAES
                                          NULL,            // IV
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &encryptedSize);
    NSData *resultData = nil;
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytes:buffer length:encryptedSize];
        free(buffer);
        return resultData;
    } else {
        free(buffer);
        @throw [NSException exceptionWithName:@"Encrypt"
                                       reason:@"Encrypt Error!"
                                     userInfo:nil];
        return resultData;
    }
    return resultData;
}

@end
