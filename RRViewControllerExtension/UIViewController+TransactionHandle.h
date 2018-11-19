//
//  UIViewController+TransactionHandle.h
//  2buluInterview
//
//  Created by 罗亮富 on 2018/5/19.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 * 所有视图转换只适用于在UINavigationController、UITabBarController中的子viewController以及
 * 通过presentViewController方式弹出的视图
 * 用户自定义的containerviewController不能保证能够通过本文件的方法完成转换
 */

@interface UIViewController (TransactionHandle)

//返回最终显示在界面上的viewController，例如topPresentedViewContrller是UINavitagionController的话\
那么返回的是navigationController.topViewController.
+(UIViewController *)appTopDisplayViewController;
//返回rootViewController 的 topPresentedViewContrller
+(UIViewController *)appTopViewController;

//返回到backViewController所在的显示位置
+(void)backToViewController:(UIViewController *)backViewController
                   animated:(BOOL)flag
                 completion:(void (^)(void))cmpBlock;


//返回到本类任一显示实例对象所在的位置，并将最终返回到的界面实例对象通过block传递给调用的地方
+(void)backToExistInstanceWithCompletionBlock:(void (^)(UIViewController *existVc))block;

//寻找当前显示栈中本类的所有viewcontroller实例,block返回YES表示满足查抄条件，同时方法返回查找到的vc
+(nullable instancetype)foundExistInstanceInViewCotrollerDisplayStack:(UIViewController *)viewController
                                                            withBlock:(BOOL (^)(UIViewController *foundViewController))emBlock;

//return self if there is no presentedViewController, otherwise return the viewController presented on top
@property (nonatomic, readonly) UIViewController *topPresentedViewContrller;

//return self if there is no parentViewController, otherwise return the outside most parentviewcontroller
@property (nonatomic, readonly) UIViewController *topParentViewController;

//self所在的所有presentingViewController及presentedViewController按照顺序组成的关系数组
-(NSArray<UIViewController *> *)presentStack;

//self所在的所有parentViewController，但不包括self的childViewController(s)
-(NSArray *)parentStack;

//convinience method
-(void)pushViewController:(UIViewController *)viewController;

/**
 * 相较于-presentViewController:animated:completion:,此方法的好处是可以把一个已经显示在presentstack中的vc调到最前面显示\
 * @parameter:
 * wrapinNavigation:是否添加到一个UINavigationController中再present
 */

-(void)presentViewController:(UIViewController *)viewControllerToPresent
  wrapInNavigationControoler:(BOOL)wrapinNavigation
                    animated:(BOOL)flag
                  completion:(void (^)(void))completion;

//优先按照navigationCotroller的方式push显示，如果topPresentedViewContrller是非navigationCotroller则present
//如果viewController已经在显示栈中
-(void)showViewControllerToStackTop:(UIViewController *)viewController;


//返回到viewControllerToReplaceAndBackTo视图显示的位置，并将其替换掉
-(void)replaceAndBackToViewController:(UIViewController *)viewControllerToReplaceAndBackTo;

/*
 *从viewController的显示栈中（包括当前navigation stack，及presenting stack）中查找本类的任一实例并将其提到最前端显示。
 *@parameters:
 *viewController:从其显示栈中寻找
 *(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block: 显示前回调block,负责返回最终要显示的viewController
 *  当找到了UIViewCotrollerSubClass在当前显示栈中的任一对象，block会将该实例对象传递给block，如果没有则传递nil，
 *  block还负责返回最终要显示的viewController，典型的应用场景是：如果在viewController显示栈中找到了本类的任一实例则在block中对该实例进行处理然后返回
 *  如果没有找到的话，这直接创建一个当前类的新实例对象返回
 */
//优先push，如果顶端vc不是UINavigationController的话，则prsent
+(instancetype)showOnTopInViewCotrollerDisplayStack:(UIViewController *)viewController
                               finalDisplayInstance:(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block;

//和上一个方法区别是，永远present，wrapInNavigation:是否封装在UINavigationController中
+(instancetype)presentOnTopInViewCotrollerDisplayStack:(UIViewController *)viewController
                            wrapInNavigationController:(BOOL)wrapInNavigation
                                  finalDisplayInstance:(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block
                                            completion:(void (^)(void))completion;


@end

@interface UINavigationController (TransactionHandle)

//
-(void)bringChildViewControllerToTop:(UIViewController *)viewController animated:(BOOL)animate;

-(BOOL)removeChildViewController:(UIViewController *)viewController
                        animated:(BOOL)animate
                      completion: (void (^ __nullable)(void))completion;

-(void)showViewControllerOnTop:(UIViewController *)endViewController animated:(BOOL)animate;

@end


