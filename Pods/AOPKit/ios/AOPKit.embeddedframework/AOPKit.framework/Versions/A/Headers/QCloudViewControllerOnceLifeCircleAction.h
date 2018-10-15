//
//  QCloudViewControllerOnceLifeCircleAction.h
//  Pods
//
//  Created by stonedong on 16/10/30.
//
//

#import "QCloudViewControllerOnceLifeCircleAction.h"
#import "QCloudViewControllerLifeCircleBaseAction.h"
/**
 The action block to handle ViewController appearing firstly.
 
 @param viewController The UIViewController tha appear
 @param animated It will aminated paramter from the origin SEL paramter.
 */
typedef void (^QCloudViewControllerOnceActionWhenAppear)(id viewController, BOOL animated);


/**
 when a ViewController appear firstly , it will do something . This class is design for this situation
 */
@interface QCloudViewControllerOnceLifeCircleAction : QCloudViewControllerLifeCircleBaseAction

/**
 The action block to handle ViewController appearing firstly.
 */
@property (nonatomic, strong) QCloudViewControllerOnceActionWhenAppear actionBlock;


/**
Factory method to reduce an instance of QCloudViewControllerOnceActionWhenAppear
 @param block The handler to cover UIViewController appearing firstly
 @return an instance of QCloudViewControllerOnceActionWhenAppear
 */
+ (instancetype) actionWithOnceBlock:(QCloudViewControllerOnceActionWhenAppear)block;


/**
 a once action is an class that handle some logic once when one instance of UIViewController appear. It need a block to exe the function.
 @param  block the logic function to exe
 @return an instance of QCloudVCOnceLifeCircleAction
 */
- (instancetype) initWithBlock:(QCloudViewControllerOnceActionWhenAppear)block;

@end
