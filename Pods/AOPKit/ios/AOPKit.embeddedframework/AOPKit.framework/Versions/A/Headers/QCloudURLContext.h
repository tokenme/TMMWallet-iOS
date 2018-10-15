//
//  QCloudURLContext.h
//  Pods
//
//  Created by tencent on 2016/11/10.
//
//

#import <Foundation/Foundation.h>

@interface QCloudURLContext : NSObject

/**
 set an value by key

 @param value value
 @param key key
 */
- (void) setWeakValue:(id)value forKey:(NSString*)key;


/**
 set an bool value by key

 @param value value
 @param key key
 */
- (void) setBoolValue:(BOOL)value forKey:(NSString*)key;


/**
 get an bool value by key

 @param key key
 @return value
 */
- (BOOL) boolValueForKey:(NSString*)key;



/**
 set int value by key

 @param value value
 @param key key
 */
- (void) setIntValue:(int)value forKey:(NSString*)key;


/**
 get int value by key

 @param key key
 @return value
 */
- (int) intValueForKey:(NSString*)key;
@end
