//
//  UIViewController+GlobalConfig.m
//  llf 2015.07

#import "UIViewController+GlobalConfig.h"
#import <objc/runtime.h>
#if DEBUG
#define ALERT_VIEWCONTROLLER_LEAK 1
#endif


static UIImage *backIndicatorImage;
static NSMutableDictionary *sBeforeHookBlockMap;
static NSMutableDictionary *sAfterHookBlockMap;
#ifdef ALERT_VIEWCONTROLLER_LEAK
static NSHashTable *sVcLeacDetectHashTable;
static NSMutableArray *vcLeakWhiteSpace;
#endif


@implementation UIViewController (GlobalConfig)
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(loadView);
        SEL swizzledSelector = @selector(exchg_loadView);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class, swizzledSelector));
        
        originalSelector = @selector(viewDidLoad);
        swizzledSelector = @selector(exchg_viewDidLoad);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class, swizzledSelector));
        
        originalSelector = @selector(viewWillAppear:);
        swizzledSelector = @selector(exchg_viewWillAppear:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class,swizzledSelector));
        
        originalSelector = @selector(viewDidAppear:);
        swizzledSelector = @selector(exchg_viewDidAppear:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class,swizzledSelector));
        
        originalSelector = @selector(viewWillDisappear:);
        swizzledSelector = @selector(exchg_viewWillDisappear:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class,swizzledSelector));
        
        originalSelector = @selector(viewDidDisappear:);
        swizzledSelector = @selector(exchg_viewDidDisappear:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class,swizzledSelector));
        
#ifdef ALERT_VIEWCONTROLLER_LEAK
        originalSelector = @selector(didMoveToParentViewController:);
        swizzledSelector = @selector(exchg_didMoveToParentViewController:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class,swizzledSelector));
        sVcLeacDetectHashTable = [NSHashTable weakObjectsHashTable];
        
        vcLeakWhiteSpace = [[NSMutableArray alloc] init];
        [vcLeakWhiteSpace addObject:@"_UIRemoteInputViewController"];
#endif
        

    });
}

+(void)hookLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod
            onTiming:(RRMethodInsertTiming)timing
           withBlock:(UIViewControllerLifecycleHookBlock)block
{
    if(block)
    {
        if(timing == RRMethodInsertTimingBefore)
        {
            if(!sBeforeHookBlockMap)
                sBeforeHookBlockMap = [NSMutableDictionary dictionary];
            
            [sBeforeHookBlockMap setObject:block forKey:@(lifecycleMethod)];
        }
        else if(timing == RRMethodInsertTimingAfter)
        {
            if(!sAfterHookBlockMap)
                sAfterHookBlockMap = [NSMutableDictionary dictionary];
    
            [sAfterHookBlockMap setObject:block forKey:@(lifecycleMethod)];
        }
    }
}

-(void)invokeBeforeHookForLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod animated:(BOOL)animate
{
    UIViewControllerLifecycleHookBlock blk = [sBeforeHookBlockMap objectForKey:@(lifecycleMethod)];
    if(blk)
        blk(self,animate);
}

-(void)invokeAfterHookForLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod animated:(BOOL)animate
{
    UIViewControllerLifecycleHookBlock blk = [sAfterHookBlockMap objectForKey:@(lifecycleMethod)];
    if(blk)
        blk(self,animate);
}

#pragma mark - exchanged life cyle methods

-(void)exchg_loadView
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleLoadView animated:NO];
    
    [self exchg_loadView];
    
    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleLoadView animated:NO];
}

- (void)exchg_viewDidLoad
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewDidLoad animated:NO];
    
    [self exchg_viewDidLoad];
    
#ifdef ALERT_VIEWCONTROLLER_LEAK
    if([self shouldDetectMememoryLeak])
        [sVcLeacDetectHashTable addObject:self];
#endif

    
#warning removed
//    if ([self isKindOfClass:[UITableViewController class]]) {
//        UITableViewController *tableVc = (UITableViewController *)self;
//        tableVc.tableView.estimatedRowHeight = 0;
//        tableVc.tableView.estimatedSectionFooterHeight = 0;
//        tableVc.tableView.estimatedSectionHeaderHeight = 0;
//    }
    
    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewDidLoad animated:NO];
}

- (void)exchg_viewWillAppear:(BOOL)animated
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewWillAppear animated:animated];
    
    [self exchg_viewWillAppear:animated];
    
#warning removed
//    if([self isKindOfClass:[UITabBarController class]])
//        return;

    //在设置了leftBarButtonItem后 需要加上下面两句，navigationColtroller的手势返回才有效
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
   // self.navigationController.interactivePopGestureRecognizer.enabled = YES;

    if(self.navigationController.applyGlobalConfig)
    {
        [self updateNavigationAppearance:animated];
    }
    
    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewWillAppear animated:animated];
}

-(void)exchg_viewDidAppear:(BOOL)animated
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewDidAppear animated:animated];
    
    [self exchg_viewDidAppear:animated];

    objc_setAssociatedObject(self, @"viewAppear", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsStatusBarAppearanceUpdate];

    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewDidAppear animated:animated];
}

- (void)exchg_viewWillDisappear:(BOOL)animated
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewWillDisappear animated:animated];
    
    [self exchg_viewWillDisappear:animated];
    
    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewWillDisappear animated:animated];
    
}

-(void)exchg_viewDidDisappear:(BOOL)animated
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewDidDisappear animated:animated];
    [self exchg_viewDidDisappear:animated];
    objc_setAssociatedObject(self, @"viewAppear", @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewDidDisappear animated:animated];
}

-(BOOL)isViewAppearing
{
    NSNumber *v = objc_getAssociatedObject(self, @"viewAppear");
    return v.boolValue;
}


#pragma mark-

-(void)setNeedsNavigationAppearanceUpdate
{
    if(self.isViewLoaded)
        [self updateNavigationAppearance:YES];
}

-(void)updateNavigationAppearance:(BOOL)animated
{
    if(!self.navigationController)
        return;
    
    if([self prefersNavigationBarHidden])
    {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    else
    {
        if (!self.searchDisplayController.isActive)
        {
            [self.navigationController setNavigationBarHidden:NO animated:animated];
        }
    }
    
    NSMutableArray *leftItems = [NSMutableArray arrayWithArray:self.navigationItem.leftBarButtonItems];
    UIBarButtonItem *backItem = self.navigationBackItem;
    if([self prefersNavigationBackItemHidden])
    {
        if([leftItems containsObject:backItem])
        {
            // remove the back item
            [leftItems removeObject:backItem];
        }
    }
    else if(![leftItems containsObject:self.navigationBackItem])
    {
        //add back item
        [leftItems insertObject:backItem atIndex:0];
    }
    self.navigationItem.leftBarButtonItems = leftItems;
    
    
    BOOL transparent = [self prefersNavigationBarTransparent];
    [self.navigationController setNavigationBarTransparent:transparent];
    if(!transparent)
    {
#warning 这里是否欠妥，如果设置为nil的话，是不是把上次设定的默认图片也覆盖了
        //set navigation bar background image
        UIImage *bgImage = [self preferredNavigationBarBackgroundImage];
        [self.navigationController.navigationBar setBackgroundImage:bgImage forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:nil];
    }
    
    
    //set navigation bar tintColor
    [self.navigationController.navigationBar setBarTintColor:[self preferredNavatationBarTintColor]];
    
    //set navigation bar item tintColor
    UIColor *barItemTintColor = [self preferredNavigationItemTintColor];
    [self.navigationController.navigationBar setTintColor:barItemTintColor];
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.tintColor = barItemTintColor;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.tintColor = barItemTintColor;
    }];
    
    //set navigation bar title attributed
    [self.navigationController.navigationBar setTitleTextAttributes:[self preferredNavigationTitleTextAttributes]];
    
}


-(UIBarButtonItem *)navigationBackItem
{
    UIBarButtonItem *backItem = objc_getAssociatedObject(self, @"backItem");
    if(!backItem)
    {
        if(!backIndicatorImage)
            backIndicatorImage = [[UIImage imageNamed:@"icon_button_return"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        backItem = [[UIBarButtonItem alloc] initWithImage:backIndicatorImage style:UIBarButtonItemStylePlain target:self action:@selector(dismissBarButtonItemEventHandle:)];
        backItem.imageInsets = UIEdgeInsetsMake(0, -2, 0, -8);//
        objc_setAssociatedObject(self, @"backItem", backItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backItem;
}

-(UIColor *)preferredNavatationBarTintColor
{
    return [UINavigationBar appearance].barTintColor;
}

-(UIColor *)preferredNavigationItemTintColor
{
    return [UINavigationBar appearance].tintColor;
}

-(NSDictionary *)preferredNavigationTitleTextAttributes
{
    return [[UINavigationBar appearance] titleTextAttributes];
}

-(UIImage *)preferredNavigationBarBackgroundImage
{
    return [[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsDefault];;
}

-(BOOL)prefersNavigationBarTransparent
{
    return NO;
}


-(BOOL)prefersNavigationBarHidden
{
    return NO;
}

-(BOOL)prefersNavigationBackItemHidden
{
    BOOL hidden = NO;
    if(!self.navigationController.presentingViewController)
    {
        if(self.navigationController.childViewControllers.count > 0)
        {
            if(self.navigationController.viewControllers.firstObject == self)
                hidden = YES;
        }
    }
   
    return hidden;
}


-(BOOL)viewControllerShouldDismiss
{
    return YES;
}


-(IBAction)dismissBarButtonItemEventHandle:(UIBarButtonItem *)backItem
{
    if([self viewControllerShouldDismiss])
    {
        UIViewController *popedVc = [self.navigationController popViewControllerAnimated:YES];
        if(!popedVc)
        {
            [self dismissView];
        }
    }
}


-(void)dismissView
{
    [self dismissViewWithCompletionBlock:nil];
}

- (void)dismissViewWithCompletionBlock: (void (^ __nullable)(void))completion
{
    [self dismissViewAnimated:YES completionBlock:completion];
    
}

- (void)dismissViewAnimated:(BOOL)animate completionBlock: (void (^ __nullable)(void))completion
{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *popBackVc = nil;
    if(weak_self.navigationController)
    {
        NSArray *viewControllers = weak_self.navigationController.viewControllers;
        NSUInteger selfIndx = [viewControllers indexOfObject:weak_self];
        if(selfIndx > 0 && selfIndx != NSNotFound)
            popBackVc = [viewControllers objectAtIndex:selfIndx-1];
    }
    
    if(popBackVc)
    {
        [weak_self.navigationController popToViewController:popBackVc animated:animate completionBlock:completion];
    }
    else if(weak_self.presentingViewController || weak_self.navigationController.presentingViewController)
    {
        [weak_self dismissViewControllerAnimated:animate completion:completion];
    }
    });
}

#pragma mark-
//是否允许侧滑返回上一级navigationController界面
-(BOOL)navigationControllerAllowSidePanPopBack
{
    if(self.navigationController.childViewControllers.count == 1)//必须增加这个判断条件 否则会阻断用户触摸事件
        return NO;
    else
    {
        return [self viewControllerShouldDismiss];
    }
    
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(gestureRecognizer == self.navigationController.interactivePopGestureRecognizer)
    {
        return [self navigationControllerAllowSidePanPopBack];
    }
    else
        return YES;
}


#pragma mark- memory leak detection

#ifdef ALERT_VIEWCONTROLLER_LEAK
- (void)exchg_didMoveToParentViewController:(nullable UIViewController *)parent
{
    [self exchg_didMoveToParentViewController:parent];
    
    if([self shouldDetectMememoryLeak])
    {
        if(!parent)
        {
            NSString *selfAddress = [NSString stringWithFormat:@"%p",self];
            [[self class] performSelector:@selector(detectLeak:) withObject:selfAddress afterDelay:1.0];
        }
    }
}

+(void)detectLeak:(NSString *)vcAddress
{
    NSMutableString *mString = [NSMutableString string];
    for(UIViewController *vc in sVcLeacDetectHashTable)
    {
        NSString *curVcAddress = [NSString stringWithFormat:@"%p",vc];
        if([curVcAddress isEqualToString:vcAddress] && !vc.parentViewController)
        {
            [mString appendFormat:@"%@:%@\n",NSStringFromClass([vc class]),vc.title];
        }
    }
    
    if(mString.length)
    {
        NSString *msg = [NSString stringWithFormat:@"potential memory leak for %@",mString];
        UIAlertView *alv = [[UIAlertView alloc] initWithTitle:@"Warning" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alv show];
    }
}

-(BOOL)shouldDetectMememoryLeak
{
    //有一些系统内部的类无需监控，所以加一个白名单过滤
    return ![vcLeakWhiteSpace containsObject:NSStringFromClass([self class])];
}

#endif


@end








