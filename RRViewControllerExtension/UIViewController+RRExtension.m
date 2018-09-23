//
//  UIViewController+RRExtension.m
//  Roen(罗亮富）zxllf23@163.com 2015.07

#import "UIViewController+RRExtension.h"
#import <objc/runtime.h>



static UIImage *backIndicatorImage;
static NSMutableDictionary *sBeforeHookBlockMap;
static NSMutableDictionary *sAfterHookBlockMap;
#if VC_MemoryLeakDetectionEnabled
static NSHashTable *sVcLeakDetectionHashTable;
static NSMutableSet *sVcLeakDetectionDefaultExceptions;
__weak UIView *sMemleakWarningView;
#endif

@implementation UIViewController (RRExtension)
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
        
#if VC_MemoryLeakDetectionEnabled
        sVcLeakDetectionHashTable = [NSHashTable weakObjectsHashTable];
        sVcLeakDetectionDefaultExceptions = [NSMutableSet setWithObjects:@"UIAlertController",
                                             @"_UIRemoteInputViewController",
                                             @"UICompatibilityInputViewController",
                                             nil];
#endif
        

    });
}

+(void)hookLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod
            onTiming:(RRMethodInsertTiming)timing
           withBlock:(RRViewControllerLifecycleHookBlock)block
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
    RRViewControllerLifecycleHookBlock blk = [sBeforeHookBlockMap objectForKey:@(lifecycleMethod)];
    if(blk)
        blk(self,animate);
}

-(void)invokeAfterHookForLifecycle:(RRViewControllerLifeCycleMethod)lifecycleMethod animated:(BOOL)animate
{
    RRViewControllerLifecycleHookBlock blk = [sAfterHookBlockMap objectForKey:@(lifecycleMethod)];
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
    
    [self showNavigationBackItem:![self prefersNavigationBackItemHidden]];

    [self invokeAfterHookForLifecycle:RRViewControllerLifeCycleViewDidLoad animated:NO];
    

}

- (void)exchg_viewWillAppear:(BOOL)animated
{
    [self invokeBeforeHookForLifecycle:RRViewControllerLifeCycleViewWillAppear animated:animated];
    
    [self exchg_viewWillAppear:animated];

    [self updateNavigationAppearance:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    // self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
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
    
#if VC_MemoryLeakDetectionEnabled
    if(self.memoryLeakDetectionEnabled)
    {
        [sVcLeakDetectionHashTable addObject:self];
        [self detectMemoryLeak];
    }
#endif
}

-(BOOL)isViewAppearing
{
    NSNumber *v = objc_getAssociatedObject(self, @"viewAppear");
    return v.boolValue;
}


#pragma mark-

-(void)showNavigationBackItem:(BOOL)show
{
    NSMutableArray *leftItems = [NSMutableArray arrayWithArray:self.navigationItem.leftBarButtonItems];
    UIBarButtonItem *backItem = self.navigationBackItem;
    if(show)
    {
        if(![leftItems containsObject:backItem])
        {
            [leftItems insertObject:backItem atIndex:0];
        }
    }
    else if([leftItems containsObject:backItem])
    {
        [leftItems removeObject:backItem];
    }
    self.navigationItem.leftBarButtonItems = leftItems;
}

-(void)updateNavigationAppearance:(BOOL)animated
{
    if(!self.navigationController || !self.isViewLoaded)
        return;
    
    if([self prefersNavigationBarHidden])
    {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        if (!self.searchDisplayController.isActive)
        {
            [self.navigationController setNavigationBarHidden:NO animated:animated];
        }
#pragma clang diagnostic pop
    }
    
    
    BOOL transparent = [self prefersNavigationBarTransparent];
    [self.navigationController setNavigationBarTransparent:transparent];
    if(!transparent)
    {
//#warning 这里是否欠妥，如果设置为nil的话，是不是把上次设定的默认图片也覆盖了
        //set navigation bar background image
        UIImage *bgImage = [self preferredNavigationBarBackgroundImage];
        [self.navigationController.navigationBar setBackgroundImage:bgImage forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:nil];
    }
    
    
    //set navigation bar tintColor
    [self.navigationController.navigationBar setBarTintColor:[self preferredNavatationBarColor]];
    
    //set navigation bar item tintColor
    UIColor *barItemTintColor = [self preferredNavigationItemColor];
    [self.navigationController.navigationBar setTintColor:barItemTintColor];
    
    
    //set navigation bar title attributed
    [self.navigationController.navigationBar setTitleTextAttributes:[self preferredNavigationTitleTextAttributes]];
    
}


-(UIBarButtonItem *)navigationBackItem
{
    UIBarButtonItem *backItem = objc_getAssociatedObject(self, @"backItem");
    if(!backItem)
    {
        if(!backIndicatorImage)
        {
            backIndicatorImage = [[UIImage imageNamed:@"icon_button_return"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        backItem = [[UIBarButtonItem alloc] initWithImage:backIndicatorImage style:UIBarButtonItemStylePlain target:self action:@selector(dismissBarButtonItemEventHandle:)];
        backItem.imageInsets = UIEdgeInsetsMake(0, -2, 0, -8);//
        objc_setAssociatedObject(self, @"backItem", backItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backItem;
}

-(UIColor *)preferredNavatationBarColor
{
    UIColor *c = self.navigationController.defaultNavatationBarColor;
    if(!c)
        c = [UINavigationBar appearance].barTintColor;
    
    return c;
}

-(UIColor *)preferredNavigationItemColor
{
    UIColor *c = self.navigationController.defaultNavigationItemColor;
    if(!c)
        c =  [UINavigationBar appearance].tintColor;
    
    return c;
}

-(NSDictionary *)preferredNavigationTitleTextAttributes
{
    NSDictionary *dic = self.navigationController.defaultNavigationTitleTextAttributes;
    
    if(!dic)
        dic = [[UINavigationBar appearance] titleTextAttributes];
    
    return dic;
}

-(UIImage *)preferredNavigationBarBackgroundImage
{
    UIImage *img = self.navigationController.defaultNavigationBarBackgroundImage;

    if(!img)
        img = [[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    return img;
}

-(BOOL)prefersNavigationBarTransparent
{
    return self.navigationController.defaultNavigationBarTransparent;
}


-(BOOL)prefersNavigationBarHidden
{
    return self.navigationController.defaultNavigationBarHidden;
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

-(void)navitationItemPush
{
    [self.navigationItem popStatus];
}
-(void)navitationItemPop
{
    [self.navigationItem pushStatus];
}

#pragma mark-

-(IBAction)dismissBarButtonItemEventHandle:(UIBarButtonItem *)backItem
{
    if([self viewControllerShouldDismiss])
    {
        [self dismissView];
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
    UIViewController *popBackVc = nil;
    if(self.navigationController)
    {
        NSArray *viewControllers = weak_self.navigationController.viewControllers;
        NSUInteger selfIndx = NSNotFound;//
        
        UIViewController *tmpVc = self;
        
        //这个操作骚不骚？Coquettish operation 就这么叫吧
        for(int i=0; i<1000; i++) //limit loop time to avoid dead loop
        {
            selfIndx = [viewControllers indexOfObject:tmpVc];
            if(selfIndx != NSNotFound)
                break;
            
            tmpVc = tmpVc.parentViewController;
        }
        
        
        if(selfIndx > 0 && selfIndx != NSNotFound)
            popBackVc = [viewControllers objectAtIndex:selfIndx-1];
    }
    
    if(popBackVc)
    {
        [self.navigationController popToViewController:popBackVc animated:animate completionBlock:completion];
    }
    else if(self.presentingViewController || self.navigationController.presentingViewController)
    {
        [self dismissViewControllerAnimated:animate completion:completion];
    }
}

#pragma mark-
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

-(void)detectMemoryLeak
{
#if VC_MemoryLeakDetectionEnabled
    if(self == [UIApplication sharedApplication].keyWindow.rootViewController)
        return;
    
    __weak typeof(self) weak_self = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if(weak_self
           && !weak_self.parentViewController
           && !weak_self.presentingViewController
           && !weak_self.view.superview)
        {
            __strong typeof(weak_self) strong_self = weak_self;
            if([sVcLeakDetectionHashTable containsObject:strong_self])
            {
                [strong_self didReceiveMemoryLeakWarning];
            }
        }
    });
    
#endif
}

-(void)didReceiveMemoryLeakWarning
{
#if VC_MemoryLeakDetectionEnabled
    NSString *info = [NSString stringWithFormat:@" %@:%@",NSStringFromClass([self class]),self.title];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    if(!sMemleakWarningView)
    {
        UIView *v = [[UIView alloc]initWithFrame:CGRectMake(0, keyWindow.frame.size.height - 100, keyWindow.frame.size.width, 100)];
        v.alpha = 0.9;
        [keyWindow addSubview:v];
        
        UITextView *txV = [[UITextView alloc]initWithFrame:v.bounds];
        txV.tag = 23;
        txV.editable = NO;
        txV.backgroundColor = [UIColor redColor];
        txV.textColor = [UIColor yellowColor];
        txV.font  = [UIFont systemFontOfSize:14];
        txV.text = @"Memory leak warnings:";
        [v addSubview:txV];
        
        UIButton *clsBtn = [[UIButton alloc]initWithFrame:CGRectMake(txV.frame.size.width-50, 5, 44, 30)];
        clsBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        [clsBtn setTitle:@"x" forState:UIControlStateNormal];
        [clsBtn setTintColor:[UIColor greenColor]];
        [clsBtn addTarget:self action:@selector(closeWarning) forControlEvents:UIControlEventTouchUpInside];
        [v addSubview:clsBtn];
        
        sMemleakWarningView = v;
    }
    
    UITextView *txV = [sMemleakWarningView viewWithTag:23];
    
    NSMutableString *mStr = [NSMutableString stringWithString:txV.text];
    [mStr appendFormat:@"\n%@",info];
    txV.text = mStr;
    [keyWindow bringSubviewToFront:sMemleakWarningView];
    NSLog(@"WARNING:Detected memory leak with %@",info);
#endif
}

#if VC_MemoryLeakDetectionEnabled
-(void)closeWarning
{
    [sMemleakWarningView removeFromSuperview];
}
#endif

-(void)setEnabledMemoryLeakDetection:(BOOL)enable
{
#if VC_MemoryLeakDetectionEnabled
    objc_setAssociatedObject(self, @"memleakDetec", [NSNumber numberWithBool:enable], OBJC_ASSOCIATION_RETAIN);
#endif
}

-(BOOL)memoryLeakDetectionEnabled
{
#if VC_MemoryLeakDetectionEnabled
    NSNumber *n = objc_getAssociatedObject(self, @"memleakDetec");
    if(n)
        return n.boolValue;
    else
    {
        NSString *myClassStr = NSStringFromClass([self class]);
        return ![sVcLeakDetectionDefaultExceptions containsObject:myClassStr];
    }
#else
    return NO;
#endif
}

+(NSMutableSet<NSString *> *)memoryLeakDetectionExcludedClasses
{
#if VC_MemoryLeakDetectionEnabled
    return sVcLeakDetectionDefaultExceptions;
#else
    return nil;
#endif
}


@end








