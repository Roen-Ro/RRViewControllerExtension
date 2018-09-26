//
//  AppDelegate.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "AppDelegate.h"
#import "RRViewControllerExtension.h"
#import "DEMO_normalMemoryLeakViewController.h"
#import "CommView.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //setup app appearance
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0 green:0.45 blue:0.8 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
    NSDictionary * dict = [NSDictionary dictionaryWithObject:[UIColor yellowColor] forKey:NSForegroundColorAttributeName];
    [[UINavigationBar appearance] setTitleTextAttributes:dict];
    
    DEMO_normalMemoryLeakViewController *rtVc = [[DEMO_normalMemoryLeakViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:rtVc];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = navi;
    
    
    [UIViewController hookLifecycle:RRViewControllerLifeCycleViewDidLoad onTiming:RRMethodInsertTimingAfter withBlock:^(UIViewController * _Nonnull viewController, BOOL animated) {
        
        NSLog(@"%@ viewDidLoad",NSStringFromClass([viewController class]));

        if([NSStringFromClass([viewController class]) hasPrefix:@"DEMO_"])
        {
            viewController.view.backgroundColor = [UIColor whiteColor];
            if(!viewController.title)
                viewController.title = NSStringFromClass([viewController class]);
            
            UIBarButtonItem *ritm = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"R%d",rand()%100] style:UIBarButtonItemStylePlain target:nil action:nil];

            viewController.navigationItem.rightBarButtonItem = ritm;
            
            CommView *v = [[NSBundle mainBundle] loadNibNamed:@"CommView" owner:nil options:nil].firstObject;
            v.viewController = viewController;
            v.frame = CGRectMake(0, 88, viewController.view.frame.size.width, v.frame.size.height);
            [viewController.view addSubview:v];
            
        }
    }];
    
    
    
    [UIViewController hookLifecycle:RRViewControllerLifeCycleViewWillAppear
                           onTiming:RRMethodInsertTimingBefore
                          withBlock:^(UIViewController * _Nonnull viewController, BOOL animated) {
                              
                              NSLog(@"%@ ViewWillAppear animated:%d",NSStringFromClass([viewController class]),animated);
                          //    [MyLog logEnterPage:NSStringFromClass([viewController class])];
                          }];
    
    [UIViewController hookLifecycle:RRViewControllerLifeCycleViewDidDisappear
                           onTiming:RRMethodInsertTimingAfter
                          withBlock:^(UIViewController * _Nonnull viewController, BOOL animated) {
                              
                             // [MyLog logLeavePage:NSStringFromClass([viewController class])];
                              NSLog(@"%@ viewWillDisappear animated:%d",NSStringFromClass([viewController class]),animated);
                          }];
//
    
    return YES;
}



@end
