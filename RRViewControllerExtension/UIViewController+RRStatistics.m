//
//  UIViewController+RRStatistics.m
//  RRUIViewControllerDemo
//
//  Created by luoliangfu on 2021/12/23.
//  Copyright © 2021 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "UIViewController+RRStatistics.h"
#import <objc/runtime.h>


@implementation RRViewControllerStatistic
-(instancetype)copyWithZone:(NSZone *)zone {
    RRViewControllerStatistic *s = [[[self class] alloc] init];
    s.stayTime = self.stayTime;
    s.viewCount = self.viewCount;
    s.enterTime = self.enterTime;
    return  s;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    _enterTime = 0;
    _stayTime = [coder decodeDoubleForKey:@"stayTime"];
    _viewCount = [coder decodeIntegerForKey:@"viewCount"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeDouble:_stayTime forKey:@"stayTime"];
    [coder encodeInteger:_viewCount forKey:@"viewCount"];
}

@end



@implementation UIViewController (RRStatistics)

-(void)setStatisticName:(NSString *)statisticName {
    IMP key = class_getMethodImplementation([self class],@selector(statisticName));
    objc_setAssociatedObject(self, key, statisticName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *)statisticName {
    IMP key = class_getMethodImplementation([self class],@selector(statisticName));
    id obj = objc_getAssociatedObject(self,key);
    if(!obj)
        obj = NSStringFromClass(self.class);
    return obj;
}

-(BOOL)statisticEnabled {
    IMP key = class_getMethodImplementation([self class],@selector(statisticEnabled));
    NSNumber *num = objc_getAssociatedObject(self,key);
    if(num) {
        return num.boolValue;
    }
    else {
        
        if([self isKindOfClass:[UIAlertController class]])
            return NO;
        
        return self.childViewControllers.count == 0;
    }
}

-(void)setEnableStatistic:(BOOL)enableStatistic {
    IMP key = class_getMethodImplementation([self class],@selector(statisticEnabled));
    objc_setAssociatedObject(self, key, [NSNumber numberWithBool:enableStatistic], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)isInModalPresenting {
    
    //Tips:如果self是present包裹在navigationController中的vc,那么:\
    1> self.presentingViewController和self.navigationController.presentingViewController都是同一个 \
    2> self.modalPresentationStyle和self.navigationController.modalPresentationStyle不一定相等
    
    if(!self.presentingViewController)
        return NO;
    
    UIViewController *actualPresentedVc = self.presentingViewController.presentedViewController;
    
    if(actualPresentedVc.presentingViewController) {
        if(actualPresentedVc.modalPresentationStyle == UIModalPresentationFullScreen
           || actualPresentedVc.modalPresentationStyle == UIModalPresentationCurrentContext)
            return NO;
        else
            return YES;
    }
    return NO;
}

/**
 注意:这里不能以-viewWillDisappear:或viewDidDisappear两个方法作为页面退出依据.
 因为presentViewController如果不是UIModalPresentationFullScreen或UIModalPresentationCurrentContext模式的话，是不会触发presentingViewController的上述两个方法的
 
 modal模式，指viewController以"非"UIModalPresentationFullScreen或UIModalPresentationCurrentContext方式被present展现，这种情况下presentingViewController是不会执行-viewWillDisappear:和-viewDidDisappear两个方法的，
 
 页面访问实现逻辑
 (用vc代替viewController实例,statStack是统计记录堆栈)
 1.在-viewWillDisappear 和 -viewDidAppear执行相应代码
 
viewDidAppear:
 1.是否为modal模式
   a>是:（如果存在的话）将正在统计的vc入栈
   b>否:do nothing
 2.停止正在统计vc的统计
 3.当前是否需要统计
    a>是:开始统计vc
    b>否:do nothing

 
 viewWillDisappear:
 1.vc是否正在统计中:
    a>是:停止统计
    b>否:do nothing
 2.是否为modal模式
    a>是:恢复栈顶vc统计
    b>否:do nothing
 
 */


static NSMutableDictionary <NSString *, RRViewControllerStatistic *>*sRRStatDic;
static NSPointerArray *sRRStatStack;
__weak UIViewController *sRRStatCurrentViewController; //当前正在统计的VC


+(void)load {
    if(!sRRStatStack)
        sRRStatStack = [NSPointerArray weakObjectsPointerArray];
    
    [self rrReadStatistics];
}

+(void)rrEndStatisticViewController:(UIViewController *)viewController {
   
#warning test
    NSLog(@"----->> end:%@",NSStringFromClass(viewController.class));
    
    if(!viewController)
        return;
        
    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();

    RRViewControllerStatistic *stc = [sRRStatDic objectForKey:viewController.statisticName];
    if(stc.enterTime > 0) {
        stc.stayTime += (t0 - stc.enterTime);
    }
    
    sRRStatCurrentViewController = nil;
}

+(void)rrBeginStatisticViewController:(nonnull UIViewController *)viewController fromRecover:(BOOL)revocer {
    
    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    
    RRViewControllerStatistic *stc = [sRRStatDic objectForKey:viewController.statisticName];
    if(!stc) {
        if(revocer) {
            return; //如果是恢复的话，之前没有记录就不再做任何事情，直接返回
        }
        else {
            stc = [RRViewControllerStatistic new];
            [sRRStatDic setObject:stc forKey:viewController.statisticName];
        }
    }
    
    stc.viewCount += 1;
    stc.enterTime = t0;
    
    sRRStatCurrentViewController = viewController;
    
#warning test
    NSLog(@"*****>> Begin:%@ recover:%d",NSStringFromClass(viewController.class),revocer);
}

//只在-viewDidAppear:方法中调用
+(void)staticviewDidAppearForViewController:(UIViewController *)viewController {
    
    if([self rrShouldIgnoreSysViewController:viewController])
        return;

    //viewController是否为modal模式,将正在统计的vc入栈
    if(viewController.isInModalPresenting) {
        if(sRRStatCurrentViewController)
            [sRRStatStack addPointer:(__bridge void * _Nullable)(sRRStatCurrentViewController)];
    }
    
#if DEBUG
#warning test
    NSLog(@">>>>> DidAppear[%@] sRRStatStack.count %zu",NSStringFromClass(viewController.class),sRRStatStack.count);
#endif
    
    //停止正在统计vc的统计
    [self rrEndStatisticViewController:sRRStatCurrentViewController];
    
    //viewController是否需要统计
    if(viewController.statisticEnabled) {
        [self rrBeginStatisticViewController:viewController fromRecover:NO];
    }
    
    [self rrSaveStatistics];
}

//只在viewWillDisappear:方法中调用
+(void)staticviewWillDisappearForViewController:(UIViewController *)viewController {
    
    
    if([self rrShouldIgnoreSysViewController:viewController])
        return;
    
    //vc是否正在统计中，是的话停止统计
    if(viewController == sRRStatCurrentViewController) {
        [self rrEndStatisticViewController:viewController];
    }
    
    
#if DEBUG
#warning test
    NSLog(@"+++++ WillDisappear[%@] sRRStatStack.count %zu",NSStringFromClass(viewController.class),sRRStatStack.count);
#endif
    
    //Tips:NavigationCotroller是modal模式情况下，其willDisappear会先于其子vc调用
    //viewController是否为modal模式,是的话恢复栈顶
    if(viewController.isInModalPresenting && sRRStatStack.count > 0) {
        
        if(sRRStatCurrentViewController) {
            [self rrEndStatisticViewController:sRRStatCurrentViewController];
        }
        
        NSInteger idx = sRRStatStack.count-1;
        UIViewController *rVc = [sRRStatStack pointerAtIndex:idx];
        if(rVc) {
            [self rrBeginStatisticViewController:rVc fromRecover:YES];
            [sRRStatStack removePointerAtIndex:idx];
        }
        
#warning test
        if(sRRStatCurrentViewController == nil) {
            NSLog(@"NULL NULL NULL NULL NULL NULL NULL NULL ");
        }
    }
    
    [self rrSaveStatistics];
    
    
}

+(void)RRStaticAppEnterbackground {
    
    //停止记录并入栈
    if(sRRStatCurrentViewController) {
        [sRRStatStack addPointer:(__bridge void * _Nullable)(sRRStatCurrentViewController)];
        [self rrEndStatisticViewController:sRRStatCurrentViewController];
    }
}

+(void)RRStaticAppEnterForeground {
    
    //恢复计入并出栈
    if(sRRStatStack.count > 0) {
        NSInteger idx = sRRStatStack.count-1;
        UIViewController *rVc = [sRRStatStack pointerAtIndex:idx];
        if(rVc) {
            [self rrBeginStatisticViewController:rVc fromRecover:YES];
            [sRRStatStack removePointerAtIndex:idx];
        }
    }
}

+(BOOL)rrShouldIgnoreSysViewController:(UIViewController *)viewController {
    
    NSArray *classes = @[@"UIInputWindowController",
                         @"UIEditingOverlayViewController",
                         @"UIAlertController",
                         @"UISystemKeyboardDockController",
                         @"UINavigationController",
                         @"UITabBarController",
                         @"UIPredictionViewController"];
    for(NSString *s in classes) {
//        Class cls = NSClassFromString(s);
//        if([s isKindOfClass:cls])
//            return YES;
        
        NSString *clsStr = NSStringFromClass(viewController.class);
        if([s isEqualToString:clsStr])
            return YES;
    }
    return NO;
}


+(NSURL *)rrStatisticsArchiveUrl {
    NSURL *libraryDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryDir URLByAppendingPathComponent:@"RR.Statistics.arc"];
}

+(void)rrReadStatistics {
    if(!sRRStatDic) {
        sRRStatDic = [NSKeyedUnarchiver unarchiveObjectWithFile:[self rrStatisticsArchiveUrl].path];
        if(!sRRStatDic)
            sRRStatDic = [NSMutableDictionary dictionaryWithCapacity:128];
    }
}

+(void)rrSaveStatistics {
    [NSKeyedArchiver archiveRootObject:sRRStatDic toFile:[self rrStatisticsArchiveUrl].path];
}

+(NSDictionary <NSString *, RRViewControllerStatistic *>*)rrStatisticsData {
    return sRRStatDic.copy;
}

+(NSString *)stringifyStatistics {
    NSArray *allKeys = [sRRStatDic allKeys];
    NSArray *sortedNames = [allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        RRViewControllerStatistic *s1 = [sRRStatDic objectForKey:(NSString *)obj1];
        RRViewControllerStatistic *s2 = [sRRStatDic objectForKey:(NSString *)obj2];
        
        if(s1.stayTime > s2.stayTime)
            return NSOrderedAscending;
        else if(s1.stayTime < s2.stayTime)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    NSMutableString *mString = [NSMutableString stringWithCapacity:5000];
    for(NSString *n in sortedNames) {
        RRViewControllerStatistic *s1 = [sRRStatDic objectForKey:n];
        [mString appendFormat:@"%@: stayed %.3f(min), viewd %zu;\n",n,s1.stayTime/60.0,s1.viewCount];
    }
    
    return mString;
}

@end
