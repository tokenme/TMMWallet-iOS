//
//  TACCoreConstants.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/9.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString* const TACErrorDomainCore;

#define TACDEPRECATED_METHOD(version) __attribute__((deprecated("Please use other method. TAC deprecated this method at version"#version)))

#pragma mark ----- Module Name Defines


FOUNDATION_EXTERN NSString* const TACOptionsProject;
FOUNDATION_EXTERN NSString* const TACServiceAnalytics;
FOUNDATION_EXTERN NSString* const TACServiceCrash;
FOUNDATION_EXTERN NSString* const TACServiceMessaging;
FOUNDATION_EXTERN NSString* const TACServicePayment;
FOUNDATION_EXTERN NSString* const TACServiceStorage;
FOUNDATION_EXTERN NSString* const TACServiceAuthorization;
FOUNDATION_EXTERN NSString* const TACServiceSocial;
FOUNDATION_EXTERN NSString* const TACServiceSocialWechat;

#pragma mark ----- Social Modules
FOUNDATION_EXTERN NSString* const TACServiceSocialQQ;


#pragma mark ---DEBUG KEYS

FOUNDATION_EXPORT NSString* const kTACDebugOption;


#pragma mark ---Module Application Configurations

#define MODULE_OPTIONS_DECODE_METHOD(module) - (void) tacOptionsDecode##module:(NSDictionary*)dic 
