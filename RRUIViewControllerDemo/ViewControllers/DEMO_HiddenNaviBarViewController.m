//
//  HiddenNaviBarViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DEMO_HiddenNaviBarViewController.h"

@interface DEMO_HiddenNaviBarViewController ()

@end

@implementation DEMO_HiddenNaviBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(BOOL)prefersNavigationBarHidden
{
    return YES;
}

#warning test
-(void)dealloc
{
    
}

@end
