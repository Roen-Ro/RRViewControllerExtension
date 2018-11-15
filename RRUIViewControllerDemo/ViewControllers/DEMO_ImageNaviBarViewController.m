//
//  ImageNaviBarViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DEMO_ImageNaviBarViewController.h"



@implementation DEMO_ImageNaviBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:.88 alpha:1];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = rightItem;
    self.title = @"IMAGE";
    self.view.backgroundColor = [UIColor yellowColor];
}

-(nullable UIImage *)preferredNavigationBarBackgroundImage
{
    return [UIImage imageNamed:@"cusNavigationBar"];
}


@end
