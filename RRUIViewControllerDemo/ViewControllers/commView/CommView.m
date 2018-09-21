//
//  CommView.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "CommView.h"
#import "DynamicConfigViewController.h"
#import "RRUIViewControllerExtension.h"

@implementation CommView
{
    IBOutlet UILabel *_vcNameLabel;
    
}


- (IBAction)toNormalVc:(id)sender {
    [self pushToViewControllerOfClass:@"DEMO_normalMemoryLeakViewController"];
}

- (IBAction)toBarHiddenVc:(id)sender {
    [self pushToViewControllerOfClass:@"DEMO_HiddenNaviBarViewController"];
}

- (IBAction)toImageBarVc:(id)sender {
    [self pushToViewControllerOfClass:@"DEMO_ImageNaviBarViewController"];
}


- (IBAction)toDynamicVc:(id)sender
{
   DynamicConfigViewController *dyVc = [[DynamicConfigViewController alloc] initWithNibName:@"DynamicConfigViewController" bundle:nil];
    [self.viewController.navigationController pushViewController:dyVc animated:YES];
}

- (IBAction)foreceDismiss:(id)sender {
    [self.viewController dismissViewAnimated:YES completionBlock:^{
        NSLog(@"%@ dismiss completed",NSStringFromClass([self.viewController class]));
    }];
}

-(void)pushToViewControllerOfClass:(NSString *)classStr
{
    Class cls = NSClassFromString(classStr);
    if(cls)
    {
        UIViewController *vc = [[cls alloc] init];
        [self.viewController.navigationController pushViewController:vc animated:YES];
    }
    
}

-(void)setViewController:(UIViewController *)viewController
{
    _viewController = viewController;
    _vcNameLabel.text = [NSString stringWithFormat:@"%@ %p",NSStringFromClass([self.viewController class]),self.viewController];
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
}


@end
