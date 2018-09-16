//
//  QCloudURLDelayCommand.h
//  Pods
//
//  Created by tencent on 2017/2/8.
//
//

#import <Foundation/Foundation.h>

@class QCloudRouteRequestContext;

/**
 use for delay load page.  when the app luanch by the window is not ready, you call route to an page. it may be fail, so i delay the route command.  it will be routed when the window is ready.
 */
@interface QCloudURLDelayCommand : NSObject

/**
 the route request context
 */
@property (nonatomic, strong, readonly) QCloudRouteRequestContext* context;

/**
 the page location
 */
@property (nonatomic, strong, readonly) NSURL * url;

- (instancetype) initWithURL:(NSURL*)url context:(QCloudRouteRequestContext*)context;
@end
