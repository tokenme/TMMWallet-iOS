//
//  TACMessagingDeviceToken+Private.h
//  TACMessaging
//
//  Created by Dong Zhao on 2017/11/21.
//

#import  "TACMessagingDeviceToken.h"

@interface TACMessagingDeviceToken ()
- (instancetype) initWithTokenString:(NSString*)tokenString;
- (void) bindUserIdentifier:(NSString*)userIdentifier;
@end
