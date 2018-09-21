//
//  UIViewController+RRExtension.h
//  created by Roen(罗亮富） On 2015.07 (zxllf23@163.com)
// github: https://github.com/Roen-Ro/RRViewControllerExtension

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


//do not enable this macro in release mode
#if DEBUG
#define VC_MemoryLeakDetectionEnabled 1
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^RRViewControllerLifecycleHookBlock) (UIViewController *viewController, BOOL animated);



@interface UIViewController (RRExtension) <UIGestureRecognizerDelegate>

@property (nonatomic,readonly) BOOL isViewAppearing;


#pragma mark- UINavigation related
/*----------------methods below are for sublclass to override ------------*/

//return YES to hide navigationBar and NO ro display navigationBar
-(BOOL)prefersNavigationBarHidden;

//default returns NO, you can override this method to return different values according to the current status of the viewcontroller.
-(BOOL)prefersNavigationBarTransparent;

-(nullable UIColor *)preferredNavatationBarColor;
-(nullable UIColor *)preferredNavigationItemColor;
-(nullable UIImage *)preferredNavigationBarBackgroundImage;
-(nullable NSDictionary *)preferredNavigationTitleTextAttributes;

/*
 this method is invoked with user interaction with the navigation back item to pop back or dismiss the view controller, return YES to continue the dismiss process, return NO to block the dismission.
 the typicall use of this method is for an editable view controller, when user taaped on the back bottonItem, you can show alert the user to double check if the user really want to leave the page. if the user selected the "YES" option for the alert, you should directly call any of those method -dismissView,-dismissViewWithCompletionBlock:,-dismissViewAnimated:completionBlock:.
 */
-(BOOL)viewControllerShouldDismiss;

//defaults NO for navigation root view controller and YES for others
-(BOOL)navigationControllerAllowSidePanPopBack;

/*--------------------------------------------------*/

#pragma mark-

// force update,should be called whenever the return values for the view controller's navigation appearance have changed.
-(void)updateNavigationAppearance:(BOOL)animated;

//show/hide the navigation back buttonItem on left of the navigation bar
-(void)showNavigationBackItem:(BOOL)show;

//push current navigation item
-(void)navitationItemPush;
//pop the last pushed navigation item
-(void)navitationItemPop;


#pragma mark- dismiss
//pop/dismiss viewcontroller methods
- (void)dismissView;
- (void)dismissViewWithCompletionBlock: (void (^ __nullable)(void))completion;
- (void)dismissViewAnimated:(BOOL)animate completionBlock:(void (^ __nullable)(void))completion;

#pragma mark- memory leak detection

 //Unavailable in release mode. \
in debug mode, defalut is NO for classes returned from +memoryLeakDetectionExcludedClasses method and YES for others
@property (nonatomic,getter = memoryLeakDetectionEnabled) BOOL enabledMemoryLeakDetection;

//read and add or remove values from the returned set to change default excluded memory detection classes
+(NSMutableSet<NSString *> *)memoryLeakDetectionExcludedClasses;

//for subclass to override
-(void)didReceiveMemoryLeakWarning;



#pragma mark- hook

/*
 Adds a block of code before/after the `lifecycleMethod`
 @param lifecycleMethod the lifecycle method being hooked.
 @param timing before or after the life cylce method
 @param block the block code to implement the hook
 
 NOTE:the newlly set hook blocks will take place of the older ones with the same lifecycle method and same timing
 Optionally you can use Aspects(https://github.com/steipete/Aspects) to add hook for any objc method
 */
+(void)hookLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod
            onTiming:(RRMethodInsertTiming)timing
           withBlock:(RRViewControllerLifecycleHookBlock)block;


@end

NS_ASSUME_NONNULL_END




