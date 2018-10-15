//
//  QCloudURLRouteResponse.h
//  Pods
//
//  Created by tencent on 2016/11/10.
//
//

#import <Foundation/Foundation.h>
#import "QCloudRouteResponseContext.h"

/**
 the result of routing. it will contains the result and other resources.
 */
@interface QCloudURLRouteResponse : NSObject

/**
 the result of routing
 */
@property (nonatomic, assign, readonly) BOOL result;

/**
 the context for response. it will contains the paramters or info that the handler produce.
 */
@property (nonatomic, readonly, strong) QCloudRouteResponseContext*  context;
+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithResult:(BOOL)result NS_DESIGNATED_INITIALIZER;

/**
 @return a success response with default context
 */
+ (QCloudURLRouteResponse*) successResponse;

/**
 @return a fail response with default context
 */
+ (QCloudURLRouteResponse*) faildResponse;

/**
 creat an instance of QCloudURLRouteResponse with result and mainResource.

 @param result the handler result
 @param mainResource handler produce resoucrce
 @return creat an instance of QCloudURLRouteResponse
 */
+ (QCloudURLRouteResponse*) responseResult:(BOOL)result withMainResouce:(id)mainResource ;
@end
