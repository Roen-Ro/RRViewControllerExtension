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

//only for memmory leak test 仅用于vc内存泄露测试
NSMutableArray *sVcMemLeakDebugArray;
static int sCreatedCount;

@implementation DEMO_normalMemoryLeakViewController

+(void)initialize
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
    DEMO_normalMemoryLeakViewController *vc1 = [[DEMO_normalMemoryLeakViewController alloc] init];
    DEMO_ImageNaviBarViewController *vc2 = [[DEMO_ImageNaviBarViewController alloc] init];
    vc2.title = @"img";
    DynamicConfigViewController *vc3 = [[DynamicConfigViewController alloc] initWithNibName:@"DynamicConfigViewController" bundle:nil];
    vc3.title = @"dyn";
    
    SwitchableViewController *svc = [[SwitchableViewController alloc] initWithViewControllers:@[vc1,vc2,vc3]];
    
    [self.navigationController pushViewController:svc animated:YES];
    
}

-(IBAction)presentNavigationWrappedVc:(id)sender
{
    DEMO_normalMemoryLeakViewController *vc = [[DEMO_normalMemoryLeakViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    navi.defaultNavatationBarColor = [UIColor greenColor];
    navi.defaultNavigationTitleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
    [self presentViewController:navi animated:YES completion:nil];
}

//set system MFMessageComposeViewController to ignore settings
- (IBAction)pushMFMsgComposeVc:(id)sender
{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *sendMessageVC = [[MFMessageComposeViewController alloc]init];
        sendMessageVC.messageComposeDelegate = self;
        sendMessageVC.defaultNavigationBarHidden = YES;
        sendMessageVC.recipients = @[@"13714854091"];
        sendMessageVC.body  = @"Hello world";
        [self.navigationController presentViewController:sendMessageVC animated:YES completion:nil];
    }
    else
        NSLog(@"MFMessageComposeViewController is not available");
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
}



@end
