//
//  QCloudUIStackLifeCircleAction.h
//  Pods
//
//  Created by yishuiliunian on 2016/11/2.
//
//

#import "QCloudViewControllerLifeCircleAction.h"

/**
 Global Notificatio for first view did appear. it track all UIViewController with viewDidAppear and post the notification when first UIViewController  did appear.
 */
extern NSString* QCloudUIStackNotificationRootVCLoaded;

/**
 this action inherit from an AOP base class named QCloudViewControllerLifeCircleBaseAction.  responsibility of this class is that hold a stack for all  UIViewController that is appearing. It will register an instance of class when +load. and the instance is singloton. Useing it you can get the appearing view stack.
 */
@interface QCloudUIStackLifeCircleAction : QCloudViewControllerLifeCircleBaseAction

/**
 the appearing UIViewController stack. you can use it to find some UIViewController that meet the conditions.
 */
@property (nonatomic, strong, readonly) NSArray* viewControllerStack;


/**
 the root viewcontroller is loaded or not
 */
@property (nonatomic, assign, readonly) BOOL rootViewControllerLoaded;
@end



/**
 The singloton of QCloudUIStackLifeCircleAction. you global ui stack is in it.

 @return the singloton of QCloudUIStackLifeCircleAction
 */
FOUNDATION_EXTERN QCloudUIStackLifeCircleAction* QCloudUIShareStackInstance(void);
