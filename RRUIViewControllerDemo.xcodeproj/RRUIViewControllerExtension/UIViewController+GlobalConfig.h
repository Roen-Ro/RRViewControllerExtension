//
//  UIViewController+GlobalConfig.h
//  created by Roen Ro(罗亮富） On 2015.07 (zxllf23@163.com)

#import <UIKit/UIKit.h>
#import "UINavigationController+RRSet.h"


typedef enum {
    
    RRMethodInsertTimingBefore = 0,
    RRMethodInsertTimingAfter
    
}RRMethodInsertTiming;


typedef enum {
    
    RRViewControllerLifeCycleLoadView = 0,
    RRViewControllerLifeCycleViewDidLoad,
    RRViewControllerLifeCycleViewWillAppear,
    RRViewControllerLifeCycleViewDidAppear,
    RRViewControllerLifeCycleViewWillDisappear,
    RRViewControllerLifeCycleViewDidDisappear,
    
}RRViewControllerLifeCycleMethod;

NS_ASSUME_NONNULL_BEGIN

typedef void (^UIViewControllerLifecycleHookBlock) (UIViewController *viewController, BOOL animated);

/*
-shouldLogPageViewEvent removed
-hideStatusbarOnViewAppear removed, use system default method prefersStatusBarHidden
-showDefaultNavigationBackItem removed
-hideNavigationBarOnViewAppear -> prefersNavigationBarHidden
-transparentNavigationBarOnViewAppear -> prefersNavigationBarTransparent
 navigationBarTintColorOnViewAppear -> preferredNavatationBarTintColor;
 navigationBarItemTintColorOnViewAppear -> preferredNavigationItemTintColor
 navigationBarBackgroundImageOnViewAppear -> preferredNavigationBarBackgroundImage;
 navigationBarTitleAttributedOnViewAppear -> preferredNavigationTitleTextAttributes
 navigationControllerShouldPopBack -> viewControllerShouldDismiss
 navigationContollerSideSlipShouldPopBack -> navigationControllerAllowSidePanPopBack
 shouldShowPopButton -> prefersNavigationBackItemHidden
 isViewAppeared -> isViewAppearing
 */

@interface UIViewController (GlobalConfig) <UIGestureRecognizerDelegate>

@property (nonatomic,readonly) BOOL isViewAppearing;


/*----------------methods below are for sublclass to override ------------*/

//return YES to hide navigationBar and NO ro display navigationBar
-(BOOL)prefersNavigationBarHidden;

//default returns NO, you can override this method to return different values according to the current status of the viewcontroller.
-(BOOL)prefersNavigationBarTransparent;

-(nullable UIColor *)preferredNavatationBarTintColor;
-(nullable UIColor *)preferredNavigationItemTintColor;
-(nullable UIImage *)preferredNavigationBarBackgroundImage;
-(nullable NSDictionary *)preferredNavigationTitleTextAttributes;
-(BOOL)prefersNavigationBackItemHidden; //defaults YES for navigation root view controller and NO for others

//this method is invoked each time user tapped on navigation back item to pop back or the "close" bottonItem on navigation bar to dismiss a modal view controller, return YES to continue the dismiss process. return NO to block the dismission.\
the typicall use of this method is for an editable view controller, when user taaped on the back bottonItem, you can show alert to double check if the user really want to leave the page. if the user make selected the "YES" option for the alert, you should directly call any of those method -dismissView,-dismissViewWithCompletionBlock:,-dismissViewAnimated:completionBlock:.
-(BOOL)viewControllerShouldDismiss;

//defaults NO for navigation root view controller and YES for others
-(BOOL)navigationControllerAllowSidePanPopBack;

/*----------------sublclass to override methods end------------*/


// Should be called whenever the return values for the view controller's navigation appearance have changed.
-(void)setNeedsNavigationAppearanceUpdate;


#pragma mark- dismiss methods
- (void)dismissView;
- (void)dismissViewWithCompletionBlock: (void (^ __nullable)(void))completion;
- (void)dismissViewAnimated:(BOOL)animate completionBlock:(void (^ __nullable)(void))completion;

#pragma mark- class methods

/*
 Adds a block of code before/after the `lifecycleMethod`
 @param lifecycleMethod: the lifecycle method being hooked.
 @param timing: before or after the life cylce method
 @param block: the block code to implement the hook
 
 NOTE:the newlly set hook blocks will take place of the older ones with the same lifecycle method and same timing
 
 Optionally you can use Aspects(https://github.com/steipete/Aspects) to add hook for any objc method
 */
+(void)hookLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod
            onTiming:(RRMethodInsertTiming)timing
           withBlock:(UIViewControllerLifecycleHookBlock)block;


@end

NS_ASSUME_NONNULL_END




