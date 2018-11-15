//
//  DynamicConfigViewController.m
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "DynamicConfigViewController.h"
#import "RRViewControllerExtension.h"
#import "DEMO_ImageNaviBarViewController.h"

// do not confused with code in this file, most of it is for the
@implementation DynamicConfigViewController
{
    
    __weak IBOutlet UIButton *_hiddenBtn;
    __weak IBOutlet UIButton *_transparentBtn;
    __weak IBOutlet UIButton *_barColorBtn;
    __weak IBOutlet UIButton *_itemColorBtn;
    __weak IBOutlet UIButton *_titleAttributeBtn;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"dynamic appearance";
    
    UIBarButtonItem *ritm2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_apple"] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = ritm2;
    
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    [self randomChange:nil];
    
}


#pragma mark- appearance
-(BOOL)prefersNavigationBarHidden
{
    return self.navigationBarHidden;
}

-(BOOL)prefersNavigationBarTransparent
{
    return self.navigationBarTransparent;
}

-(nullable UIColor *)preferredNavigationItemColor
{
    return self.navigationItemColor;
}

-(nullable UIColor *)preferredNavatationBarColor
{
    return self.navigationBarColor;
}

-(nullable NSDictionary *)preferredNavigationTitleTextAttributes
{
    return self.navigationTitleAttribute;
}

-(void)forceNavigationAppearanceUpdate
{
    if(self.navigationBarHidden)
    {
        [_hiddenBtn setTitle:@"navigation bar is hidden" forState:UIControlStateNormal];
        [_hiddenBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
    else
    {
        [_hiddenBtn setTitle:@"navigation bar is shown" forState:UIControlStateNormal];
        [_hiddenBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    
    if(self.navigationBarTransparent)
    {
        [_transparentBtn setTitle:@"navigation bar is transparent" forState:UIControlStateNormal];
        [_transparentBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
    else
    {
        [_transparentBtn setTitle:@"navigation bar is opaque" forState:UIControlStateNormal];
        [_transparentBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    
    [_barColorBtn setTitleColor:self.navigationBarColor forState:UIControlStateNormal];
    [_itemColorBtn setTitleColor:self.self.navigationItemColor forState:UIControlStateNormal];
    NSAttributedString *atrStr = [[NSAttributedString alloc] initWithString:_titleAttributeBtn.titleLabel.text attributes:self.navigationTitleAttribute];
    [_titleAttributeBtn setAttributedTitle:atrStr forState:UIControlStateNormal];

    
    [self updateNavigationAppearance:YES];
}

#pragma mark- button actions

- (IBAction)hiddenSwitch:(UIButton *)sender
{
    self.navigationBarHidden = !self.navigationBarHidden;
    [self forceNavigationAppearanceUpdate];
}

- (IBAction)opaqueSwitch:(UIButton *)sender {
    
    self.navigationBarTransparent = !self.navigationBarTransparent;
    self.navigationBarHidden = NO;
    [self forceNavigationAppearanceUpdate];
}

- (IBAction)barColorChange:(UIButton *)sender {
    
    self.navigationBarColor = [self randomColor];
    self.navigationBarHidden = NO;
    self.navigationBarTransparent = NO;
    [self forceNavigationAppearanceUpdate];
}

- (IBAction)itemColorChange:(UIButton *)sender {
  
    self.self.navigationItemColor = [self randomColor];
    self.navigationBarHidden = NO;
    [self forceNavigationAppearanceUpdate];
}

- (IBAction)titleAttributeChange:(UIButton *)sender {
    
    self.navigationTitleAttribute = @{NSForegroundColorAttributeName:[self randomColor],NSFontAttributeName:[UIFont systemFontOfSize:rand()%10+10]};
    self.navigationBarHidden = NO;
    [self forceNavigationAppearanceUpdate];
}


-(IBAction)pushToImageNaviBar:(UIButton *)sender
{
    DEMO_ImageNaviBarViewController *vc = [[DEMO_ImageNaviBarViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES completionBlock:^{
        NSLog(@"finish push to DEMO_ImageNaviBarViewController");
    }];
    
}

-(IBAction)randomChange:(id)sender
{
    self.navigationBarHidden = NO;
    self.navigationBarTransparent = !rand()%3;
    self.navigationBarColor = [self randomColor];
    self.navigationItemColor = [self randomColor];
    self.navigationTitleAttribute = @{NSForegroundColorAttributeName:[self randomColor],NSFontAttributeName:[UIFont systemFontOfSize:rand()%10+10]};
    
    [self forceNavigationAppearanceUpdate];
}

#pragma mark-

-(UIColor *)randomColor
{
    return [UIColor colorWithRed:rand()%20/20.0 green:rand()%20/20.0 blue:rand()%20/20.0 alpha:1];
}



@end
