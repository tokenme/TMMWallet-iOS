//
//  DetectApp.h
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

#ifndef DetectApp_h
#define DetectApp_h

#import <Foundation/Foundation.h>

@interface DetectApp: NSObject
+ (BOOL)isInstalled:(NSString *)bundleId schemeId: (UInt64)schemeId;
@end

#endif /* DetectApp_h */
