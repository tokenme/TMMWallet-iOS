//
//  TMMBeacon.h
//  TMMBeacon
//
//  Created by Syd on 2018/7/27.
//  Copyright © 2018年 tokenmama.io. All rights reserved.
//

#ifndef TMMBeacon_h
#define TMMBeacon_h

extern const NSString * TMMToastPositionTop;
extern const NSString * TMMToastPositionCenter;
extern const NSString * TMMToastPositionBottom;

@interface TMMBeacon: NSObject
    
+(instancetype) shareInstance;
+(instancetype)initWithKey:(NSString *)key secret:(NSString *)secret;
- (void) start;
- (void) stop;
- (void) disableNotification;
- (void) setToastPosition:(NSString *)toastPosition;
- (void) setToastBackgroundColor: (UIColor *) color;
- (void) setToastTitleColor: (UIColor *) color;
- (void) setToastMessageColor: (UIColor *) color;
- (void) setToastDuration:(NSTimeInterval)duration;
- (void) setNotificationInterval:(NSTimeInterval)notificationInterval;
- (void) debugToast;
- (NSDictionary *) deviceInfo;
- (NSString *) deviceId;
@end

#endif /* TMMBeacon_h */
