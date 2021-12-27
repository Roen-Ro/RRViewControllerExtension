//
//  UIViewController+RRStatistics.h
//  RRUIViewControllerDemo
//
//  Created by luoliangfu on 2021/12/23.
//  Copyright © 2021 深圳市两步路信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface RRViewControllerStatistic : NSObject<NSCopying,NSCoding>
@property (nonatomic) CFAbsoluteTime enterTime; //The time entered the viewController
@property (nonatomic) NSTimeInterval stayTime; //Stay duration in the viewController for each statistic time
@property (nonatomic) NSInteger viewCount; //total view count for a viewController

@end



@interface UIViewController (RRStatistics)

//the name used for the viewcontroller's view statistics, default is the viewcontroller's class name
@property (nonatomic,strong) NSString *statisticName;

/**
 Whether the viewcontroller should be considered while doing the view statistics.
 default value: NO for those who have children viewcontrollers such as UINavigationController, UITabViewController etc. YES for ohters that doesn't have any children viewcontrollers
 */
@property (nonatomic, getter = statisticEnabled) BOOL enableStatistic;

@property (nonatomic, readonly) BOOL isInModalPresenting;

//Read statistics data
+(NSDictionary <NSString *, RRViewControllerStatistic *>*)rrStatisticsData;

//stringified statistic data for analysisy purpose
+(NSString *)stringifyStatistics;

//Only call this method in UIApplicationDelegate's -applicationDidBecomeActive:
+(void)RRStaticAppEnterForeground;

//Only call this method in UIApplicationDelegate's -applicationDidEnterBackground:
+(void)RRStaticAppEnterbackground;
@end




NS_ASSUME_NONNULL_END
