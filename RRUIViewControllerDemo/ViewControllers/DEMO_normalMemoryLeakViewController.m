//
//  AppRootViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DEMO_normalMemoryLeakViewController.h"
#import "RRViewControllerExtension.h"
#import "SwitchableViewController.h"
#import "DynamicConfigViewController.h"
#import "DEMO_ImageNaviBarViewController.h"
#import "DEMO_normalMemoryLeakViewController.h"
#import <MessageUI/MessageUI.h>

//only for memmory leak debug 仅用于vc内存泄露调试
NSMutableArray *sVcMemLeakDebugArray;
static int sCreatedCount;

@implementation DEMO_normalMemoryLeakViewController

+(void)load
{
    if(!sVcMemLeakDebugArray)
        sVcMemLeakDebugArray = [NSMutableArray array];
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    // Do any additional setup after loading the view.
    sCreatedCount++;
    self.title = [NSString stringWithFormat:@"Normal %d",sCreatedCount];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [sVcMemLeakDebugArray addObject:self];
}


-(BOOL)viewControllerShouldDismiss
{
    UIAlertController *alvCtrl = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Override -[UIViewController viewControllerShouldDismiss] method and return NO will block the view dismiss, you can show an alert in this method" preferredStyle:UIAlertControllerStyleAlert];

    [alvCtrl addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:nil]];
    [alvCtrl addAction:[UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissView];
        });


    }]];

    [self presentViewController:alvCtrl animated:YES completion:nil];

    return NO;
}



-(IBAction)presentNavigationWrappedVc:(id)sender
{
    DEMO_normalMemoryLeakViewController *vc = [[DEMO_normalMemoryLeakViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    navi.defaultNavatationBarColor = [UIColor greenColor];
    navi.defaultNavigationTitleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
    [self presentViewController:navi animated:YES completion:nil];
}





@end
