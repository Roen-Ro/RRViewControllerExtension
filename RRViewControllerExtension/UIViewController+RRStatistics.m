//
//  UIViewController+RRStatistics.m
//  RRUIViewControllerDemo
//
//  Created by luoliangfu on 2021/12/23.
//  Copyright © 2021 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "UIViewController+RRStatistics.h"
#import <objc/runtime.h>

@interface RRViewControllerStatistic : NSObject<NSCopying>
@property (nonatomic) CFAbsoluteTime enterTime; //页面进入时间戳
@property (nonatomic) CFAbsoluteTime stayTime; //页面停留时间,本次启动后总的累计
@property (nonatomic) NSInteger viewCount; //页面访问次数

@end

@implementation RRViewControllerStatistic
-(instancetype)copyWithZone:(NSZone *)zone {
    RRViewControllerStatistic *s = [[[self class] alloc] init];
    s.stayTime = self.stayTime;
    s.viewCount = self.viewCount;
    s.enterTime = self.enterTime;
    return  s;
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
        return self.childViewControllers.count == 0;
    }
}

-(void)setEnableStatistic:(BOOL)enableStatistic {
    IMP key = class_getMethodImplementation([self class],@selector(statisticEnabled));
    objc_setAssociatedObject(self, key, [NSNumber numberWithBool:enableStatistic], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)isInModalPresenting {
    if(self.presentingViewController) {
        if(self.modalPresentationStyle == UIModalPresentationFullScreen
           || self.modalPresentationStyle == UIModalPresentationCurrentContext)
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


static NSMutableDictionary *sRRStatDic;
static NSPointerArray *sRRStatStack;
__weak UIViewController *sRRStatCurrentViewController; //当前正在统计的VC


+(void)load {
    if(!sRRStatStack)
        sRRStatStack = [NSPointerArray weakObjectsPointerArray];
    
    if(!sRRStatDic) {
        sRRStatDic = [NSMutableDictionary dictionaryWithCapacity:128];
    }
    
}

//只在-viewDidAppear:方法中调用
+(void)staticviewDidAppearForViewController:(UIViewController *)viewController {

    //viewController是否为modal模式,将正在统计的vc入栈
    if(viewController.isInModalPresenting) {
        if(sRRStatCurrentViewController)
            [sRRStatStack addPointer:(__bridge void * _Nullable)(sRRStatCurrentViewController)];
    }
    
    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    
    //停止正在统计vc的统计
    if(sRRStatCurrentViewController) {
        RRViewControllerStatistic *stc = [sRRStatDic objectForKey:sRRStatCurrentViewController.statisticName];
        if(stc.enterTime > 0) {
            stc.stayTime += (t0 - stc.enterTime);
        }
    }
    sRRStatCurrentViewController = nil;
    
    
    //viewController是否需要统计
    if(viewController.statisticEnabled) {
        RRViewControllerStatistic *stc = [sRRStatDic objectForKey:viewController.statisticName];
        if(!stc) {
            stc = [RRViewControllerStatistic new];
            [sRRStatDic setObject:stc forKey:viewController.statisticName];
        }
        
        stc.viewCount += 1;
        stc.enterTime = t0;
        
        sRRStatCurrentViewController = viewController;
    }
}

//只在viewWillDisappear:方法中调用
+(void)staticviewWillDisappearForViewController:(UIViewController *)viewController {
    
    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    
    //vc是否正在统计中，是的话停止统计
    if(viewController == sRRStatCurrentViewController) {
        RRViewControllerStatistic *stc = [sRRStatDic objectForKey:sRRStatCurrentViewController.statisticName];
        if(stc.enterTime > 0) {
            stc.stayTime += (t0 - stc.enterTime);
        }
        
        sRRStatCurrentViewController = nil;
    }
    
    //viewController是否为modal模式,是的话恢复栈顶
    if(viewController.isInModalPresenting && sRRStatStack.count > 0) {
        NSInteger idx = sRRStatStack.count-1;
        UIViewController *rVc = [sRRStatStack pointerAtIndex:idx];
        if(rVc) {
            RRViewControllerStatistic *stc = [sRRStatDic objectForKey:rVc.statisticName];
            if(stc) {
                stc.viewCount += 1;
                stc.enterTime = t0;
            }
            
            sRRStatCurrentViewController = rVc;
            [sRRStatStack removePointerAtIndex:idx];
        }
    }
}

+(void)RRStaticAppEnterbackground {
    
    //停止记录并入栈
    if(sRRStatCurrentViewController) {
        CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
        [sRRStatStack addPointer:(__bridge void * _Nullable)(sRRStatCurrentViewController)];
        RRViewControllerStatistic *stc = [sRRStatDic objectForKey:sRRStatCurrentViewController.statisticName];
        if(stc.enterTime > 0) {
            stc.stayTime += (t0 - stc.enterTime);
        }
        
        sRRStatCurrentViewController = nil;
    }
}

+(void)RRStaticAppEnterForeground {
    
    //恢复计入并出栈
    if(sRRStatStack.count > 0) {
        CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
        NSInteger idx = sRRStatStack.count-1;
        UIViewController *rVc = [sRRStatStack pointerAtIndex:idx];
        if(rVc) {
            RRViewControllerStatistic *stc = [sRRStatDic objectForKey:rVc.statisticName];
            if(stc) {
                stc.viewCount += 1;
                stc.enterTime = t0;
            }
            
            sRRStatCurrentViewController = rVc;
            [sRRStatStack removePointerAtIndex:idx];
        }
    }
}




@end
