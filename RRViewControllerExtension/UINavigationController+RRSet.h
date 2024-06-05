//
//  UINavigationController+RRSet.h
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富(Roen).
//



#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface UINavigationBar (RRSet)
-(void)reloadBarBackgroundImage:(nullable UIImage *)img;
-(void)reloadBarShadowImage:(nullable UIImage *)img;
-(void)reloadBarBackgroundColor:(nullable UIColor *)color;
-(void)reloadBarTitleTextAttributes:(nullable NSDictionary<NSAttributedStringKey, id>*)titleTextAttributes;
@end

typedef void (^TransitionCompletionCallBackType)(void);

@interface UINavigationController (RRSet)

@property (nonatomic, getter = isNavigationBarTransparent) BOOL navigationBarTransparent;

// set default navigation bar appearance
@property (nonatomic) BOOL defaultNavigationBarHidden;
@property (nonatomic) BOOL defaultNavigationBarTransparent;

@property (nonatomic,copy) UIColor *defaultNavatationBarColor;
@property (nonatomic,copy) UIColor *defaultNavigationItemColor;
@property (nonatomic,strong) UIImage *defaultNavigationBarBackgroundImage;
@property (nonatomic,copy) NSDictionary *defaultNavigationTitleTextAttributes;

// pop/push with completion block call backs
- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
           completionBlock:(nullable TransitionCompletionCallBackType)completion;

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated
                                         completionBlock:(nullable TransitionCompletionCallBackType)completion;

- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController
                                                              animated:(BOOL)animated
                                                       completionBlock:(nullable TransitionCompletionCallBackType)completion;

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
                                                                   completionBlock:(nullable TransitionCompletionCallBackType)completion;

@end



@interface UINavigationItem (StatusStack)
-(void)popStatus;
-(void)pushStatus;

@end

NS_ASSUME_NONNULL_END
