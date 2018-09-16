//
//  QCloudViewControllerLifeCircleBaseAction.h
//  Pods
//
//  Created by yishuiliunian on 16/10/31.
//
//

#import <Foundation/Foundation.h>
/**
 There is so much business logic between UIViewController appearing and disappearing.  The common way to put thoese logics into every subclass of UIViewController is inheriting. But problem comes when we want to add some logic to UIViewControll which is in other's SDK so that we cannot view or change the code inside. The only thing we can do is subclassing, creating another class from it, and goes on. After having so many classes added in the progress to implement the common logic, nightmare comes when PM don't want that logic anymore after that. Thinking if the logic is like toy bricks. If it is fine, put it in. If it is not fine, remove it off. So easy. When call it AOP(Aspect Oriented Program) usually.
     
 This class's aim is that building the foundation about AOP to UIVIewController. I swizzed the appear status function. And make this class's method be called when appear status changed. Then you subclass this class and implitation your logic.
 */
@interface QCloudViewControllerLifeCircleBaseAction : NSObject

@property  (nonatomic, weak, readonly) UIViewController * liveViewController;

/**
 Each action have an unique identifier. 1to1 relation.
 */
@property (nonatomic, strong) NSString* identifier;



/**
 When a instance of UIViewController's view will appear , it will call this method. And post the instance of UIViewController

 @param vc the instance of UIViewController that will appear
 @param animated  appearing is need an animation , this will be YES , otherwise NO.
 */
- (void) hostController:(UIViewController*)vc viewWillAppear:(BOOL)animated;


/**
 When a instance of UIViewController's view did appeared. It will call this method, and post the instance of UIViewController which you can modify it.

 @param vc the instance of UIViewController that did appeared
 @param animated appearing is need an animation , this will be YES, otherwise NO.
 */
- (void) hostController:(UIViewController*)vc viewDidAppear:(BOOL)animated;


/**
 When a instance of UIViewController will disappear, it will call this method, and post the instance of UIViewController which you can modify it.

 @param vc the instance of UIViewController that will disappear
 @param animated dispaaring is need an animation , this will be YES, otherwise NO.
 */
- (void) hostController:(UIViewController*)vc viewWillDisappear:(BOOL)animated;



/**
 When a UIViewController did disappear, it will call this method ,and post the instance of UIViewController which you can modify it.

 @param vc the instance of UIViewControll that did disppeared.
 @param animated disappearing is need an animation, this will be YES, otherwise NO.
 */
- (void) hostController:(UIViewController*)vc viewDidDisappear:(BOOL)animated;
@end
