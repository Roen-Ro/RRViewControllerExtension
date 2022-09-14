//
//  UINavigationController+RRSet.h
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富 on 2018/9/17.
//

/*
 navigationBarTrasnparent -> navigationBarTransparent
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (RRSet)

@property (nonatomic) BOOL applyGlobalConfig;
@property (nonatomic, getter=isNavigationBarTransparent) BOOL navigationBarTransparent;

-(instancetype)initWithRootViewController:(UIViewController *)rootViewController applyGlobalConfig:(BOOL)apply;


// pop/push with completion block call backs
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion;
- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion;
- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion;
- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion;

@end



@interface UINavigationItem (StatusStack)
//恢复之前push的NavigationItem
-(void)popStatus;
//保存NavigationItem
-(void)pushStatus;

@end

NS_ASSUME_NONNULL_END
