//
//  StatisticsViewController.m
//  RRUIViewControllerDemo
//
//  Created by luoliangfu on 2021/12/27.
//  Copyright © 2021 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "StatisticsViewController.h"
#import "UIViewController+RRStatistics.h"

@interface StatisticsViewController ()

@end

@implementation StatisticsViewController {
    UITextView *_textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Statistics";
    _textView = [[UITextView alloc] init];
    _textView.editable = NO;
    _textView.frame = self.view.bounds;
    [self.view addSubview:_textView];
    
    
    NSString *s = [UIViewController stringifyStatistics];
    _textView.text = s;
}




@end
