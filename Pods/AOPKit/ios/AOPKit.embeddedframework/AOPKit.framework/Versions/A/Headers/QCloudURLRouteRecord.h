//
//  QCloudURLRouteRecord.h
//  Pods
//
//  Created by yishuiliunian on 2016/11/2.
//
//

#import <Foundation/Foundation.h>

@class QCloudURLRouteResponse;
@class QCloudURLRouteRequest;
typedef QCloudURLRouteResponse* (^QCloudURLRouteLocationResourceHandler)(QCloudURLRouteRequest* request);

/**
 it is a record of URL pattern that is stored at QCloudURLRoute. This class is not public , just is used in QCloudURLRoute lib.
 */
@interface QCloudURLRouteRecord : NSObject
@property (nonatomic, strong, readonly) NSString* partern;
@property (nonatomic, strong, readonly) QCloudURLRouteLocationResourceHandler handler;
- (instancetype) initWithPartern:(NSString*)partern handler:(QCloudURLRouteLocationResourceHandler)handler;
- (BOOL) canHandlerRequestURL:(NSString *)url;


/**
 比较两个Record
 1. A > B 当A能够响应B的pattern的时候
 2. B > A 当B能够响应A的pattern的时候

 @param record 另外一个需要比较的对象，如果不为QCloudURLRouteRecord类型会抛出异常
 @return 关系
 */
- (NSComparisonResult) compreWithRecord:(QCloudURLRouteRecord*)record;
@end
