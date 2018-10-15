//
//  TACRuningEnviroment.h
//  TACCore
//
//  Created by Dong Zhao on 2017/11/30.
//

#import <Foundation/Foundation.h>

@interface TACRuningEnviroment : NSObject
+ (BOOL) develping;
+ (BOOL) getBoolByKey:(NSString*)key;
+ (NSString*) getStringByKey:(NSString*)key;
+ (int) getIntByKey:(NSString*)key;
@end
