//
//  UIViewController+appearSwizzedBlock.h
//  Pods
//
//  Created by stonedong on 16/10/29.
//
//

#import <UIKit/UIKit.h>

#import "QCloudViewControllerLifeCircleBaseAction.h"

/**
 every instance of UIViewController have a action cache. This category provide the API to manipulate this cache.
 */
@interface UIViewController (appearSwizzedBlock)

/**
 all life circle actions for current UIViewController

 @return all life circle actions for current UIViewController
 */
- (NSArray<QCloudViewControllerLifeCircleBaseAction*>*) lifeCircleActions;


/**
 add an instance of QCloudViewControllerLifeCircleBaseAction to the instance of UIViewController or it's subclass.

 @param action the action that will be inserted in to the cache of UIViewController's instance.
 */
- (QCloudViewControllerLifeCircleBaseAction* )registerLifeCircleAction:(QCloudViewControllerLifeCircleBaseAction *)action;


/**
 remove an instance of QCloudViewControllerLifeCircleBaseAction from the instance of UIViewController or it's subclass.

 @param action the action that will be removed from cache.
 */
- (void) removeLifeCircleAction:(QCloudViewControllerLifeCircleBaseAction *)action;
@end



/**
 This function will remove the target instance from the global cache . Global action will be call when every UIViewController appear. if you want put some logic into every instance of UIViewController, you can user it.
 
 @param action the action that will be rmeove from global cache.
 */
FOUNDATION_EXTERN void QCloudVCRemoveGlobalAction(QCloudViewControllerLifeCircleBaseAction* action);



/**
 This function will add an instance of QCloudViewControllerLifeCircleBaseAction into the global cache. Global action will be call when every UIViewController appear. if you want put some logic into every instance of UIViewController, you can user it.
 
 @param action the action that will be insert into global cache
 */

FOUNDATION_EXTERN void QCloudVCRegisterGlobalAction(QCloudViewControllerLifeCircleBaseAction* action);
