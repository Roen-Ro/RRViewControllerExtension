//
//  DynamicConfigViewController.h
//  RRUIViewControllerDemo
//
//  Created by 罗亮富(Roen) on 2018/9/18.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DynamicConfigViewController : UIViewController

@property (nonatomic) BOOL navigationBarHidden;
@property (nonatomic) BOOL navigationBarTransparent;
@property (nonatomic, copy) UIColor *navigationBarColor;
@property (nonatomic, copy) UIColor *navigationItemColor;
@property (nonatomic, copy) NSDictionary *navigationTitleAttribute;

@end

NS_ASSUME_NONNULL_END
