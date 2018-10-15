//
//  QCloudURLRouter.h
//  Pods
//
//  Created by yishuiliunian on 2016/11/2.
//
//

#import <Foundation/Foundation.h>
#import "QCloudURLRouteRecord.h"
#import "QCloudURLRouteRequest.h"
#import "QCloudURLRouteUtils.h"
#import "QCloudUIStackLifeCircleAction.h"
#import "QCloudURLRouteResponse.h"
#import "UINavigationController+QCloudURLRouter.h"
#import "NSObject+QCloudURLRouter.h"


/**
 QCloudURLRoute is an lib to location any objective-c controller and route it. this call provide API. what you will do is just to add the handler , then route a url that is registed pattern.
 */
@interface QCloudURLRouter : NSObject

/**
 all route records
 */
@property (nonatomic, strong, readonly) NSArray<QCloudURLRouteRecord*>* allRouteRecords;

// disable the  initialize method that is not used.
+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) copy NS_UNAVAILABLE;
- (instancetype) mutableCopy NS_UNAVAILABLE;
//

/**
 singloton of route. it hold the records of route pattern.

 @return singloton of router
 */
+ (QCloudURLRouter*)defaultRouter;


/**
 insert an route pattern to default router. it is designed every pattern must be unique. it maybe use priority next version , if so it can be not unique. 
 the handler is block. it post an QCloudURLRequest that is the program context. you can use it to find something usefully.

 @param routePattern the route pattern to mate URL
 @param handler handle the request when a URL is mate the pattern
 */
- (void) addRoutePattern:(NSString*)routePattern handler:(QCloudURLRouteLocationResourceHandler)handler;


/**
 if all pattern is not mated, then this one will be called. It handle the not found action.

 @param handler the 404 handler
 */
- (void) add404Handler:(QCloudURLRouteLocationResourceHandler)handler;



/**
 remote an route pattern handler. after you do that, when you call route page , it will be fail or route to 404 page.

 @param routePattern route pattern.
 */
- (void) removeRoutePatternHandler:(NSString*)routePattern;

/**
 we use the stand URL to locate page. so you just post an url to start a page. like:
 scheme://host/pwd?need=0&name=22 . don't worry about the start of page, i will post you the navigation and UI stack via the request paramter.

 @param url the location of an page
 @return if router can  hanle the url, it will be YES, otherwise NO.
 */
- (BOOL) routeURL:(NSURL*)url;

/**
 we use the stand URL to locate resources. so you just post an url to start a page. like:
 scheme://host/pwd?need=0&name=22 . don't worry about the start of page, i will post you the navigation and UI stack via the request paramter.
 
 @param url the location of an page
 @param context the context will be past to handler. it may be some object that can't transform to NSString
 @return if router can  hanle the url, it will be YES, otherwise NO.
 */
- (BOOL) routeURL:(NSURL *)url context:(QCloudRouteRequestContext*)context;


/**
 we use the stand URL to locate. so you jusat post an url to start a page. Like:scheme://host/pwd?need=0&name=22 . don't worry about the start of page, i will provice for you the navigation and UI stack via the request context (default).
 This function diffrent of ```routeURL:```. routeURL will route the url dirctly, but this function will be paused when your root ViewController disappeared. it is very usefully when another app wake up your app, and you will show some page.
 @param url the location of an page
 @param context the context will be past to handler. it may be some object that can't transform to NSString
 */
- (void) routePage:(NSURL*)url context:(QCloudRouteRequestContext*)context;

/**
 Location a resource in app. it may be object, or page, or a subclass of UIViewControllerLifeCircleAction. We use the stand URL to location the resources.
 
 for example you can specifie a 'Set BackgroundColor LifeCircleAction' with pattern 'services://style?background=black', and the request the action to injecte it in any instance of UIViewController.
 
 Eg:
 
 ~~~
 + (void) load
 {
    [[QCloudURLRouter defaultRouter] addRoutePattern:@"services//action/style/background" handler:^QCloudURLRouteResponse *(QCloudURLRouteRequest *request) {
        UIColor* color = [request.context valueForKey:@"color"];
        QCloudBackgroundColorAction* action = [[QCloudBackgroundColorAction alloc] init];
        action.color = color;
        return [QCloudURLRouteResponse responseResult:YES withMainResouce:action];
    }];
 }
 ~~~
 
 ~~~
    QCloudRouteRequestContext* context = [QCloudRouteRequestContext new];
    [context setValue:color forKey:@"color"];
    QCloudURLRouteResponse* response = [[QCloudURLRouter defaultRouter] locationResource:QCloudURLRouteQueryLink(@"services//action/style/background", @{}) context:context redirect404:NO];
    QCloudUIStackLifeCircleAction* action = response.context.mainResource;
    if (action) {
        [vc registerLifeCircleAction:action];
    }
 ~~~
 @param url the location of resource
 @param context the context will be past to handler. it may be some object that can't transform to NSString
 @return an resposonse that contains all the key-value pair of result
 */
- (QCloudURLRouteResponse*) locationResource:(NSURL *)url context:(QCloudRouteRequestContext *)context redirect404:(BOOL)redirect;



@end
