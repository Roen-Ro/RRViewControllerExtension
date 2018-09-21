//
//  AppRootViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DEMO_normalMemoryLeakViewController.h"
#import "RRUIViewControllerExtension.h"

//only for memmory leak test 仅用于vc内存泄露测试
NSMutableArray *sVcMemLeakDebugArray;
static int sCreatedCount;

@implementation DEMO_normalMemoryLeakViewController

+(void)initialize
{
    if(!sVcMemLeakDebugArray)
        sVcMemLeakDebugArray = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    sCreatedCount++;
    self.title = [NSString stringWithFormat:@"Normal %d",sCreatedCount];
    [sVcMemLeakDebugArray addObject:self];
}


-(BOOL)viewControllerShouldDismiss
{
    UIAlertController *alvCtrl = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Do you really want to leave this page?" preferredStyle:UIAlertControllerStyleAlert];

    [alvCtrl addAction:[UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil]];
    [alvCtrl addAction:[UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissView];
        });


    }]];

    [self presentViewController:alvCtrl animated:YES completion:nil];

    return NO;
}


-(IBAction)presentNaked:(id)sender
{
    DEMO_normalMemoryLeakViewController *vc = [[DEMO_normalMemoryLeakViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(IBAction)presentNavigationWrappedVc:(id)sender
{
    DEMO_normalMemoryLeakViewController *vc = [[DEMO_normalMemoryLeakViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navi animated:YES completion:nil];
}

@end
