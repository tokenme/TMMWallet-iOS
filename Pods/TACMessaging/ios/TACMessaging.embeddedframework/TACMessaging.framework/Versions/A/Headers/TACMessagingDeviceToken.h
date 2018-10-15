//
//  TACMessagingDeviceToken.h
//  TACMessaging
//
//  Created by Dong Zhao on 2017/11/20.
//

#import <Foundation/Foundation.h>


/**
 用于接受Apns的设备token
 */
@interface TACMessagingDeviceToken : NSObject

/**
 用于接受Apns的设备token
 */
@property (nonatomic, strong, readonly) NSString* deviceTokenString;


/**
 绑定一个主题
 
 @param tag 主题
 */
- (void) bindTag:(NSString *)tag;

/**
 解绑一个主题
 
 @param tag 主题
 */
- (void) unbindTag:(NSString*)tag;

@end
