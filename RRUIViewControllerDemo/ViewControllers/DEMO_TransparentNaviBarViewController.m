//
//  DEMO_TransparentNaviBarViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富 on 2018/12/12.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DEMO_TransparentNaviBarViewController.h"


@implementation DEMO_TransparentNaviBarViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(BOOL)prefersNavigationBarTransparent
{
    return YES;
}

-(nullable UIColor *)preferredNavigationItemColor {
    return UIColor.cyanColor;
}

@end
