//
//  UIViewController+TransactionHandle.m
//  2buluInterview
//
//  Created by 罗亮富 on 2018/5/19.
//  Copyright © 2018年 深圳市两步路信息技术有限公司. All rights reserved.
//

#import "UIViewController+TransactionHandle.h"

@implementation UIViewController (TransactionHandle)

+(UIViewController *)appTopDisplayViewController
{
    UIViewController * rootViewController = [[UIApplication sharedApplication].keyWindow.rootViewController topPresentedViewContrller];
    return [self findTopDisplayViewControllerInDisplayStack:rootViewController];
}

+(UIViewController *)appTopViewController
{
    return [[UIApplication sharedApplication].keyWindow.rootViewController topPresentedViewContrller];
}

+(UIViewController *)findTopDisplayViewControllerInDisplayStack:(UIViewController *)inStackViewController
{
    if(inStackViewController.childViewControllers.count > 0)
    {
        if([inStackViewController isKindOfClass:[UITabBarController class]])
        {
            UITabBarController *tabVc = (UITabBarController *)inStackViewController;
            return [self findTopDisplayViewControllerInDisplayStack:tabVc.selectedViewController];
        }
        else if([inStackViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *naviVc = (UINavigationController *)inStackViewController;
            return [self findTopDisplayViewControllerInDisplayStack:naviVc.topViewController];
        }
        else if ([inStackViewController isKindOfClass:[UISplitViewController class]])
        {
            UISplitViewController* svc = (UISplitViewController*)inStackViewController;
            return [self findTopDisplayViewControllerInDisplayStack:svc.viewControllers.lastObject];
        }
        else if([inStackViewController respondsToSelector:@selector(currentViewController)])
        {
            return [inStackViewController performSelector:@selector(currentViewController) withObject:nil];
        }
        else if([inStackViewController respondsToSelector:@selector(currentDisplayViewController)])
        {
            return [inStackViewController performSelector:@selector(currentDisplayViewController) withObject:nil];
        }
    }
    
    return inStackViewController;
    
}

+(void)backToViewController:(UIViewController *)backVc
                   animated:(BOOL)flag
                 completion:(void (^)(void))cmpBlock
{
    
    UIViewController *rootPresentedVc = backVc.presentedViewController;
    if(!rootPresentedVc)
    {
        UIViewController *parentVc = backVc.parentViewController;
        while (parentVc.parentViewController)
        {
            parentVc = parentVc.parentViewController;
        }
        rootPresentedVc = parentVc.presentedViewController;
    }
    
    if(rootPresentedVc)
    {
        [rootPresentedVc dismissViewControllerAnimated:flag completion:^{
            [self backToViewController:backVc animated:flag completion:cmpBlock];
        }];
    }
    else if(backVc.navigationController && backVc.navigationController.topViewController != backVc)
    {
        [backVc.navigationController popToViewController:backVc animated:flag];
        NSTimeInterval delay = 0.01;
        if(flag)
            delay = 0.45;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self backToViewController:backVc animated:flag completion:cmpBlock];
        });
    }
    else
    {
        NSArray *stacks = [backVc parentStack];
        for(UIViewController *parentVc in stacks)
        {
            if([parentVc isKindOfClass:[UITabBarController class]])
            {
                UITabBarController *tabVc = (UITabBarController *)parentVc;
                NSInteger idx = [stacks indexOfObject:tabVc];
                if(idx == 0)
                    tabVc.selectedViewController = backVc;
                else
                    tabVc.selectedViewController = [stacks objectAtIndex:idx-1];
                
                break;
            }
        }
        
        if(cmpBlock)
            cmpBlock();
        
        
    }
}

+(void)backToExistInstanceWithCompletionBlock:(void (^)(UIViewController *existVc))block
{
    UIViewController *foundVc = [self foundExistInstanceInViewCotrollerDisplayStack:[self appTopDisplayViewController] withBlock:^BOOL(UIViewController *foundViewController) {
        return YES;
    }];
    
    if(foundVc)
    {
        [UIViewController backToViewController:foundVc animated:YES completion:^{
            if(block)
                block(foundVc);
        }];
    }
    else
    {
        if(block)
            block(nil);
    }
}

//是在loadView执行之前
-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

//返回到viewControllerToReplaceAndBackTo视图显示的位置，并将其替换掉
-(void)replaceAndBackToViewController:(UIViewController *)viewControllerToReplaceAndBackTo
{
    BOOL animate = (self == viewControllerToReplaceAndBackTo);
    [UIViewController backToViewController:viewControllerToReplaceAndBackTo animated:animate completion:^{
        
        if(self == viewControllerToReplaceAndBackTo)
            return;
        
        UINavigationController *naviVc = viewControllerToReplaceAndBackTo.navigationController;
        UIViewController *presentingVc = viewControllerToReplaceAndBackTo.presentingViewController;
        if(naviVc)
        {
            NSArray *vcs = naviVc.viewControllers;
            NSMutableArray *mVcs = [NSMutableArray arrayWithArray:vcs];
            NSUInteger idx = [mVcs indexOfObject:viewControllerToReplaceAndBackTo];
            if(self.navigationController)
            {
                [self.navigationController removeChildViewController:self animated:NO completion:^{
                    [mVcs replaceObjectAtIndex:idx withObject:self];
                    [naviVc setViewControllers:mVcs animated:YES];
                }];
            }
            else
            {
                [mVcs replaceObjectAtIndex:idx withObject:self];
                [naviVc setViewControllers:mVcs animated:YES];
            }
        }
        else if(presentingVc)
        {
            if(self.presentingViewController)
            {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [viewControllerToReplaceAndBackTo dismissViewControllerAnimated:NO completion:^{
                        [presentingVc presentViewController:self animated:YES completion:nil];
                    }];
                }];
            }
            else
            {
                [viewControllerToReplaceAndBackTo dismissViewControllerAnimated:NO completion:^{
                    [presentingVc presentViewController:self animated:YES completion:nil];
                }];
            }
        }
    }];
}


//update-> self.presentingViewController must not be nil
-(void)bringToPresentedFrontAnimated:(BOOL)animate
          warpInNavigationController:(BOOL)wrapInNavigation
                          completion:(void (^)(void))cmpBlock
{
    if(self.presentingViewController == nil)
    {
        if(cmpBlock)
            cmpBlock();
        return;
    }
    
    UIViewController *topPresentingVc = self.presentingViewController;
    
    NSMutableArray *presentedStack = [NSMutableArray arrayWithCapacity:4];
    UIViewController *vc = self.presentedViewController;
    while (1) {
        if(vc)
            [presentedStack addObject:vc];
        else
            break;
        
        vc = vc.presentedViewController;
    }
    
    if(presentedStack.count == 0)
    {
        if(cmpBlock)
            cmpBlock();
        
        return;
    }
    
    //声明block
    void (^presentBlock)(NSMutableArray <UIViewController *>*,UIViewController *);
    
    __block void (^weakRefBlock)(NSMutableArray <UIViewController *>*,UIViewController *);
    //赋值block
    presentBlock = ^(NSMutableArray <UIViewController *>* tmpStack,UIViewController *tmpTopVc)
    {
        if(tmpStack.count > 0)
        {
            UIViewController *toPrVc = tmpStack.firstObject;
            BOOL ani = (tmpStack.count==1);
            [tmpTopVc presentViewController:toPrVc animated:ani completion:^{
                
                [tmpStack removeObject:toPrVc];
                if(weakRefBlock)
                    weakRefBlock(tmpStack,toPrVc);
            }];
        }
        else
        {
            if(cmpBlock)
                cmpBlock();
            
#warning 但是如果在外部调用两次及以上就会出问题了
            weakRefBlock = nil;//to break the refrence circyle
        }
    };
    
    weakRefBlock = presentBlock;
    
    UIViewController *frontVc = self;
    if(wrapInNavigation && ![self isKindOfClass:[UINavigationController class]])
    {
        frontVc = [[UINavigationController alloc] initWithRootViewController:self];
        if(!self.navigationItem.leftBarButtonItems)
            self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"关闭", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
    }
    
    [presentedStack addObject:frontVc];
    
    
    [topPresentingVc dismissViewControllerAnimated:NO completion:^{
        
        presentBlock(presentedStack,topPresentingVc);
    }];
    
}
//new
-(void)presentViewController:(UIViewController *)viewControllerToPresent
  wrapInNavigationControoler:(BOOL)wrapinNavigation
                    animated:(BOOL)flag
                  completion:(void (^)(void))completion
{
    if(viewControllerToPresent == self)
        return;
    
    void (^presentBlock)(UIViewController *) =  ^(UIViewController *vc)
    {
        if(!vc)
            return;
        
        UIViewController *finalVc = vc;
        if(wrapinNavigation && ![viewControllerToPresent isKindOfClass:[UINavigationController class]])
            finalVc = [[UINavigationController alloc] initWithRootViewController:finalVc];
        
        [self.topPresentedViewContrller presentViewController:finalVc animated:flag completion:completion];
    };
    
    if(viewControllerToPresent.navigationController)
    {
        UIViewController *presentingVc = viewControllerToPresent.navigationController.presentingViewController;
        NSArray  *subVcs = viewControllerToPresent.navigationController.viewControllers;
        if(subVcs.count == 1)
        {
            if(presentingVc)
                [viewControllerToPresent.navigationController bringToPresentedFrontAnimated:flag warpInNavigationController:wrapinNavigation completion:completion];
            else if(viewControllerToPresent.navigationController.presentedViewController)
            {
                [viewControllerToPresent.navigationController.presentedViewController dismissViewAnimated:flag completionBlock:completion];
            }
            else
            {
                //do nothing
            }
        }
        else
        {
            [viewControllerToPresent.navigationController removeChildViewController:viewControllerToPresent animated:NO completion:^{
                
                presentBlock(viewControllerToPresent);
                
            }];
        }
        
    }
    else
        if(viewControllerToPresent.presentingViewController)
            [viewControllerToPresent bringToPresentedFrontAnimated:flag warpInNavigationController:wrapinNavigation completion:completion];
        else
        {
            presentBlock(viewControllerToPresent);
        }
}

//new return self if there is no more vcs presented above current vc
-(nonnull UIViewController*)topPresentedViewContrller
{
    UIViewController *topVc = self;
    while (1) {
        UIViewController *vc = topVc.presentedViewController;
        if(vc)
            topVc = vc;
        else
            break;
    }
    
    return topVc;
}


-(UIViewController *)topParentViewController
{
    UIViewController *parentVc = self;
    
    while (parentVc.parentViewController) {
        parentVc = parentVc.parentViewController;
    }
    
    return parentVc;
}

-(void)pushViewController:(UIViewController *)viewController
{
    if([self isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *naviVc = (UINavigationController *)self;
        [naviVc pushViewController:viewController animated:YES];
    }
    else
    {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

-(NSArray *)parentStack
{
    UIViewController *parentVc = self;
    NSMutableArray *pareStack = [NSMutableArray arrayWithCapacity:2];
    [pareStack addObject:parentVc];
    
    while (1)
    {
        parentVc = parentVc.parentViewController;
        if(parentVc)
            [pareStack addObject:parentVc];
        else
            break;
    }
    
    return [NSArray arrayWithArray:pareStack];
}

-(NSArray *)presentStack
{
    NSMutableArray *presentedStack = [NSMutableArray arrayWithCapacity:4];
    UIViewController *vc = self.presentedViewController;
    while (1) {
        if(vc)
            [presentedStack addObject:vc];
        else
            break;
        
        vc = vc.presentedViewController;
    }
    
    [presentedStack insertObject:self.topParentViewController atIndex:0];
    
    vc = self.presentingViewController;
    while (1) {
        if(vc)
            [presentedStack insertObject:vc atIndex:0];
        else
            break;
        
        vc = vc.presentingViewController;
    }
    
    return [NSArray arrayWithArray:presentedStack];
}

//new
-(void)showViewControllerToStackTop:(UIViewController *)viewController
{
    UIViewController *topVc = self.topPresentedViewContrller;
    if([viewController isKindOfClass:[UINavigationController class]])
    {
        [topVc presentViewController:viewController wrapInNavigationControoler:NO animated:YES completion:nil];
    }
    else
    {
        UINavigationController *navi = nil;
        if([topVc isKindOfClass:[UINavigationController class]])
            navi = (UINavigationController *)topVc;
        else if(self.navigationController)
            navi = self.navigationController;
        else if([topVc isKindOfClass:[UITabBarController class]])
        {
            UITabBarController *tabVc = (UITabBarController *)topVc;
            UIViewController *vc001 = tabVc.selectedViewController;
            UIViewController *vc002 = vc001.topPresentedViewContrller;
            if([vc002 isKindOfClass:[UINavigationController class]])
                navi = vc002;
        }
        
        if(navi)
            [navi showViewControllerOnTop:viewController animated:YES];
        else
        {
            [topVc presentViewController:viewController wrapInNavigationControoler:NO animated:YES completion:nil];
        }
    }
}

+(nullable instancetype)foundExistInstanceInViewCotrollerDisplayStack:(UIViewController *)viewController
                                                            withBlock:(BOOL (^)(UIViewController *foundViewController))emBlock
{
    Class UIViewCotrollerSubClass = self;
    NSMutableArray *presentStack = [NSMutableArray arrayWithCapacity:3];
    UIViewController *tmVc = viewController;
    while (1) {
        tmVc = tmVc.presentingViewController;
        if(tmVc)
            [presentStack insertObject:tmVc atIndex:0];
        else
            break;
    }
    
    if(viewController.navigationController)
        [presentStack addObject:viewController.navigationController];
    else
        [presentStack addObject:viewController];
    
    tmVc = viewController;
    while (1) {
        tmVc = tmVc.presentedViewController;
        if(tmVc)
            [presentStack addObject:tmVc];
        else
            break;
    }
    //   UIViewController *foundVc = nil;
    for(UIViewController *vc in presentStack)
    {
        
        UINavigationController *naviVc = nil;
        if([vc isKindOfClass:[UINavigationController class]])
            naviVc = (UINavigationController *)vc;
        else if([vc isKindOfClass:[UITabBarController class]])
        {
            UITabBarController *tabVc = (UITabBarController *)vc;
            UIViewController *selVc = tabVc.selectedViewController;
            if([selVc isKindOfClass:[UINavigationController class]])
                naviVc = (UINavigationController *)selVc;
        }
        
        if(naviVc)
        {
            NSArray *subVcs = naviVc.viewControllers;
            for(UIViewController *sVc in subVcs)
            {
                if([sVc class] == UIViewCotrollerSubClass)
                {
                    BOOL f = emBlock(sVc);
                    if(f)
                        return sVc;
                }
            }
        }
        else
        {
            if([vc class] == UIViewCotrollerSubClass)
            {
                BOOL f = emBlock(vc);
                if(f)
                    return vc;
            }
        }
        
    }
    
    return nil;
}

/*
 *从viewController的显示栈中（包括当前navigation stack，及presenting stack）中查找本类的任一实例并将其提到最前端显示。
 *@parameters:
 *viewController:从其显示栈中寻找
 *(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block: 显示前回调block,负责返回最终要显示的viewController
 *  当找到了UIViewCotrollerSubClass在当前显示栈中的任一对象，block会将该实例对象传递给block，如果没有则传递nil，
 *  block还负责返回最终要显示的viewController，典型的应用场景是：如果在viewController显示栈中找到了本类的任一实例则在block中对该实例进行处理然后返回
 *  如果没有找到的话，这直接创建一个当前类的新实例对象返回
 */
+(instancetype)showOnTopInViewCotrollerDisplayStack:(UIViewController *)viewController
                               finalDisplayInstance:(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block
{
    UIViewController *existVc = [self foundExistInstanceInViewCotrollerDisplayStack:viewController withBlock:^(UIViewController *foundViewController) {
        return YES;
    }];
    
    UIViewController *newVc = block(existVc);
    if(newVc)
        [viewController showViewControllerToStackTop:newVc];
    
    return newVc;
}


+(instancetype)presentOnTopInViewCotrollerDisplayStack:(UIViewController *)viewController
                            wrapInNavigationController:(BOOL)wrapInNavigation
                                  finalDisplayInstance:(nonnull UIViewController* (^)(UIViewController *existViewCotroller))block
                                            completion:(void (^)(void))completion
{
    UIViewController *existVc = [self foundExistInstanceInViewCotrollerDisplayStack:viewController withBlock:^(UIViewController *foundViewController) {
        return YES;
    }];
    
    UIViewController *newVc = block(existVc);
    if(newVc)
    {
        [viewController presentViewController:newVc wrapInNavigationControoler:wrapInNavigation animated:YES completion:completion];
    }
    
    return newVc;
}

@end

@implementation UINavigationController (TransactionHandle)
-(void)bringChildViewControllerToTop:(UIViewController *)viewController animated:(BOOL)animate
{
    if(self.topViewController != viewController)
    {
        NSMutableArray *orderViewControllers = [NSMutableArray arrayWithArray:self.childViewControllers];
        UIViewController *preTop = self.topViewController;
        if([orderViewControllers containsObject:viewController])
        {
            [orderViewControllers removeObject:viewController];
            [orderViewControllers addObject:viewController];
            //  NSLog(@"1--->>block self:%@\n self.vcs:%@",self,self.viewControllers);
#warning 发现一个怪现象，这里的动画有时候是pop的动画，而不是push的动画
            [self setViewControllers:orderViewControllers animated:animate];
            //  NSLog(@"2--->>block self:%@\n self.vcs:%@",self,self.viewControllers);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                //   NSLog(@"3--->>block self:%@\n self.vcs:%@",self,self.viewControllers);
#warning    如果animate为YES的话，原来的topviewController会在动画完成之后移出当前的stack，所以要再添加回去\
目前只能想到用这种处理方式
                if(animate && !preTop.navigationController)
                {
                    [self setViewControllers:orderViewControllers animated:NO];
                }
                
            });
        }
    }
}

//update->
//如果只有rootViewController在stack中是无法移除的，没有移除的话blokc不会回调
-(BOOL)removeChildViewController:(UIViewController *)viewController animated:(BOOL)animate completion: (void (^ __nullable)(void))completion
{
    BOOL ret = NO;
    if(self.topViewController == viewController)
    {
        if(self.viewControllers.count == 1)
        {
            //            [self dismissViewControllerAnimated:animate completion:^{
            //               // self.viewControllers = nil;//
            //                if(completion)
            //                    completion();
            //            }];
            ret = NO;
        }
        else
        {
            ret = YES;
            [self popViewControllerAnimated:animate];
            NSTimeInterval delay = 0.01;
            if(animate)
                delay = 0.45;
            if(completion)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        }
        
    }
    else
    {
        NSMutableArray *orderViewControllers = [NSMutableArray arrayWithArray:self.childViewControllers];
        if([orderViewControllers containsObject:viewController])
        {
            ret = YES;
            [orderViewControllers removeObject:viewController];
            [self setViewControllers:orderViewControllers animated:NO];
            if(completion)
                completion();
            
        }
        
    }
    
    return ret;
}

//update->
-(void)showViewControllerOnTop:(UIViewController *)endViewController animated:(BOOL)animate
{
    if(!endViewController.parentViewController
       && !endViewController.presentingViewController
       && !self.presentedViewController)
    {
        [self pushViewController:endViewController animated:animate];
    }
    else
    {
        UINavigationController *fromNavigationController = endViewController.navigationController;
        UINavigationController *toNavigationController = self;
        UIViewController *topPresentedViewController = self.topPresentedViewContrller;
        
        if(topPresentedViewController)
        {
            if([topPresentedViewController isKindOfClass:[UINavigationController class]])
                toNavigationController = (UINavigationController *)topPresentedViewController;
            else
                toNavigationController = nil;
        }
        
        void (^exBlock)(void) = ^(void)
        {
            if(!endViewController.parentViewController)
            {
                if(toNavigationController)
                    [toNavigationController pushViewController:endViewController animated:animate];
                else
                {
                    UINavigationController *newNaviVc = [[UINavigationController alloc] initWithRootViewController:endViewController];
                    UIViewController *topModalVc = self.presentedViewController;
                    while (1)
                    {
                        UIViewController *tmpviewc = topModalVc.presentedViewController;
                        if(tmpviewc)
                            topModalVc = tmpviewc;
                        else
                            break;
                    }
                    if(topModalVc)
                        [topModalVc presentViewController:newNaviVc animated:animate completion:nil];
                    else
                        [self presentViewController:newNaviVc animated:animate completion:nil];
                }
            }
        };
        
        //如果endViewController已经在最顶端了，不需要再做任何事情
        if(toNavigationController.topViewController != endViewController
           && topPresentedViewController != endViewController)
        {
            
            if([fromNavigationController isEqual:toNavigationController])
                [fromNavigationController bringChildViewControllerToTop:endViewController animated:animate];
            else
            {
                BOOL removed = [fromNavigationController removeChildViewController:endViewController animated:NO completion:^{
                    exBlock();
                }];
                if(!removed)
                {
                    if(endViewController.presentingViewController)
                    {
                        [endViewController bringToPresentedFrontAnimated:YES warpInNavigationController:YES completion:nil];
                        
                    }
                    else
                    {
                        exBlock();
                    }
                }
                
            }
        }
    }
    
}


@end


