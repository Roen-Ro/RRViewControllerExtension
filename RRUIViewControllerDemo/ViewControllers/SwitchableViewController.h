//
//  SwitchableViewController.h
//  2bulu-QuanZi
//
//  Created by 罗亮富 on 14-8-14.
//  Copyright (c) 2014年 Lolaage. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SwitchableViewControllerDelegate;

@interface SwitchableViewController : UIViewController
{
@protected
    NSArray *_viewControllers;
}


-(id)initWithViewControllers:(NSArray *)viewControllers;

@property (nonatomic, weak) id<SwitchableViewControllerDelegate> delegate;

@property (nonatomic) NSUInteger displayViewControllerIndex; //显示的viewcontroller index

#warning todo 要实现setter方法
@property (nonatomic, readonly) NSArray *viewControllers;


@property (nonatomic, readonly) UISegmentedControl *segmentControl;

@property (nonatomic, readonly) UIViewController *currentViewController;

#warning todo 实现
//-(void)setBadge:(NSString *)badgeVal forChildViewController:(UIViewController *)viewController;

-(BOOL)switchToViewController:(UIViewController *)viewController;

//for subclass
-(void)willSwitchFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
-(void)didSwitchFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
@end

@protocol SwitchableViewControllerDelegate <NSObject>

@optional

-(void)switchableView:(SwitchableViewController *)switchabeViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)index;

-(BOOL)switchableView:(SwitchableViewController *)switchabeViewController shouldSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)index;

@end
