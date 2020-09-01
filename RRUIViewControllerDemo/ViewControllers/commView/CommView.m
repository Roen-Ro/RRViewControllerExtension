//
//  CommView.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "CommView.h"
#import "RRViewControllerExtension.h"
#import "SwitchableViewController.h"
#import "RRViewControllerExtension.h"
#import "DynamicConfigViewController.h"
#import "DEMO_ImageNaviBarViewController.h"
#import "DEMO_normalMemoryLeakViewController.h"

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

-(IBAction)toSwitchable:(id)sender
{
    DEMO_normalMemoryLeakViewController *vc1 = [[DEMO_normalMemoryLeakViewController alloc] init];
    DEMO_ImageNaviBarViewController *vc2 = [[DEMO_ImageNaviBarViewController alloc] init];
    vc2.title = @"img";
    DynamicConfigViewController *vc3 = [[DynamicConfigViewController alloc] initWithNibName:@"DynamicConfigViewController" bundle:nil];
    vc3.title = @"dyn";
    
    SwitchableViewController *svc = [[SwitchableViewController alloc] initWithViewControllers:@[vc1,vc2,vc3]];
    
    [self.viewController.navigationController pushViewController:svc animated:YES];
}

- (IBAction)toSysImagePicker:(id)sender {
    
    UIImagePickerController *impicker = [UIImagePickerController new];
    impicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.viewController presentViewController:impicker animated:impicker completion:^{
        
    }];
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
