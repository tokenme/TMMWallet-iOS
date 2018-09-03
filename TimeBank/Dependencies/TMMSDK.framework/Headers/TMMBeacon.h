//
//  TMMBeacon.h
//  TMMBeacon
//
//  Created by Syd on 2018/7/27.
//  Copyright © 2018年 tokenmama.io. All rights reserved.
//

#ifndef TMMBeacon_h
#define TMMBeacon_h

@interface TMMBeacon: NSObject
    
+(instancetype) shareInstance;
+(instancetype)initWithKey:(NSString *)key secret:(NSString *)secret;
- (void) start;
- (void) stop;
- (NSString *) deviceId;
@end

#endif /* TMMBeacon_h */
