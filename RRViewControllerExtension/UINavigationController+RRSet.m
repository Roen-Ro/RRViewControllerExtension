//
//  UINavigationController+RRSet.m
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富(Roen) on.
//

#import "UINavigationController+RRSet.h"
#import <objc/runtime.h>
#import "RRViewControllerExtension.h"

#pragma mark - UINavigationController (_SetupProperty)
UIKIT_EXTERN API_AVAILABLE(ios(13.0), tvos(13.0)) //NS_SWIFT_UI_ACTOR
@implementation UINavigationBar (_SetupProperty)
-(UINavigationBarAppearance*)_lazyScrollEdgeAppearance {
    UINavigationBarAppearance *scrollEdgeAppearance = self.scrollEdgeAppearance;
    if (!scrollEdgeAppearance) {
        scrollEdgeAppearance = [[UINavigationBarAppearance alloc] init];
        if ([self rr_Transparent]) {
            scrollEdgeAppearance.backgroundEffect = nil;
        }
        self.scrollEdgeAppearance = scrollEdgeAppearance;
    }
    return scrollEdgeAppearance;
}
-(UINavigationBarAppearance*)_lazyStandardAppearance {
    UINavigationBarAppearance *standardAppearance = self.standardAppearance;
    if (!standardAppearance) {
        standardAppearance = [[UINavigationBarAppearance alloc] init];
        if ([self rr_Transparent]) {
            standardAppearance.backgroundEffect = nil;
        }
        self.standardAppearance = standardAppearance;
    }
    return standardAppearance;
}

static char kAssociatedObjectKey_OrginBackgroundColor_SetupProperty;
-(void)setRr_OrginBackgroundColor:(UIColor*)rr_OrginBackgroundColor {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_OrginBackgroundColor_SetupProperty, rr_OrginBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(UIColor*)rr_OrginBackgroundColor {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_OrginBackgroundColor_SetupProperty);
}
static char kAssociatedObjectKey_Transparent_SetupProperty;
-(void)setRr_Transparent:(BOOL)rr_Transparent {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_Transparent_SetupProperty, @(rr_Transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(BOOL)rr_Transparent {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_Transparent_SetupProperty) boolValue];
}

@end


#pragma mark - UINavigationBar+RRSet
@implementation UINavigationBar (RRSet)
-(void)reloadBarBackgroundImage:(nullable UIImage *)img {
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *scrollEdgeAppearance = [self _lazyScrollEdgeAppearance];
        UINavigationBarAppearance *standardAppearance = [self _lazyStandardAppearance];
        
        scrollEdgeAppearance.backgroundImage = img;
        
        standardAppearance.backgroundImage = img;
        
    } else {
        [self setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    }
}
-(void)reloadBarShadowImage:(nullable UIImage *)img{
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *scrollEdgeAppearance = [self _lazyScrollEdgeAppearance];
        UINavigationBarAppearance *standardAppearance = [self _lazyStandardAppearance];

        scrollEdgeAppearance.shadowImage = img;
        
        standardAppearance.shadowImage = img;
        
    } else {
        [self setShadowImage:img];
    }
}
-(void)reloadBarBackgroundColor:(nullable UIColor *)color{
    if (@available(iOS 13.0, *)) {
        [self setRr_OrginBackgroundColor:color];
        UINavigationBarAppearance *scrollEdgeAppearance = [self _lazyScrollEdgeAppearance];
        UINavigationBarAppearance *standardAppearance = [self _lazyStandardAppearance];
        BOOL transparent = [self rr_Transparent];
        if (transparent) {
            scrollEdgeAppearance.backgroundColor = nil;
            standardAppearance.backgroundColor = nil;
        }else {
            scrollEdgeAppearance.backgroundColor = color;
            standardAppearance.backgroundColor = color;
        }
    } else {
        [self setBarTintColor:color];
    }
}
-(void)reloadBarTitleTextAttributes:(nullable NSDictionary<NSAttributedStringKey, id>*)titleTextAttributes{
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *scrollEdgeAppearance = [self _lazyScrollEdgeAppearance];
        UINavigationBarAppearance *standardAppearance = [self _lazyStandardAppearance];

        scrollEdgeAppearance.titleTextAttributes = titleTextAttributes;
        
        standardAppearance.titleTextAttributes = titleTextAttributes;
        
    } else {
        [self setTitleTextAttributes:titleTextAttributes];
    }
}

-(void)_reloadBarTransparent:(BOOL)transparent {
    if (@available(iOS 13.0, *)) {
        [self setRr_Transparent:transparent];
        UINavigationBarAppearance *scrollEdgeAppearance = [self _lazyScrollEdgeAppearance];
        UINavigationBarAppearance *standardAppearance = [self _lazyStandardAppearance];
        
        if (transparent) {
            standardAppearance.backgroundEffect = nil;
            scrollEdgeAppearance.backgroundEffect = nil;
        }else {
            UINavigationBarAppearance *temp = [[UINavigationBarAppearance alloc] init];
            scrollEdgeAppearance.backgroundEffect = temp.backgroundEffect;
            standardAppearance.backgroundEffect = temp.backgroundEffect;
        }
        [self reloadBarBackgroundColor:[self rr_OrginBackgroundColor]];
    }
}
@end

static char kNavigationCompletionBlockKey;
static char kNavigationBlockBckupKey;
static UIImage *sNavigationBarTransparentImage;

#pragma mark - UINavigationController + RRSet
@implementation UINavigationController (RRSet)

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL originalSelector = @selector(navigationTransitionView:didEndTransition:fromView:toView:);
        SEL swizzledSelector = @selector(mob_navigationTransitionView:didEndTransition:fromView:toView:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class, swizzledSelector));
#pragma clang diagnostic pop
        
        // for debug useage, to get the system selector message signature
        //   NSMethodSignature *sig = [class instanceMethodSignatureForSelector:originalSelector];
        //   NSLog(@"NSMethodSignature for originalSelector is %@",sig);

    });
}

#pragma mark- appearance

-(NSMutableDictionary *)navigationBarAppearanceDic
{
    NSMutableDictionary *mDic = objc_getAssociatedObject(self, @selector(navigationBarAppearanceDic));
    if(!mDic)
    {
        mDic = [NSMutableDictionary dictionaryWithCapacity:6];
        objc_setAssociatedObject(self,@selector(navigationBarAppearanceDic), mDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return mDic;
}

-(BOOL)defaultNavigationBarHidden
{
    return [[self.navigationBarAppearanceDic objectForKey:@"barHidden"] boolValue];
}

-(void)setDefaultNavigationBarHidden:(BOOL)hidden
{
    [self.navigationBarAppearanceDic setObject:[NSNumber numberWithBool:hidden] forKey:@"barHidden"];
}

-(BOOL)defaultNavigationBarTransparent
{
    return [[self.navigationBarAppearanceDic objectForKey:@"transparent"] boolValue];
}

-(void)setDefaultNavigationBarTransparent:(BOOL)transparent
{
    [self.navigationBarAppearanceDic setObject:[NSNumber numberWithBool:transparent] forKey:@"transparent"];
}

-(UIColor *)defaultNavatationBarColor
{
    return  [[self.navigationBarAppearanceDic objectForKey:@"barColor"] copy];
}

-(void)setDefaultNavatationBarColor:(UIColor *)c
{
    if(c)
        [self.navigationBarAppearanceDic setObject:[c copy] forKey:@"barColor"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"barColor"];
}

-(UIColor *)defaultNavigationItemColor
{
    return  [[self.navigationBarAppearanceDic objectForKey:@"ItmColor"] copy];
}

-(void)setDefaultNavigationItemColor:(UIColor *)c
{
    if(c)
        [self.navigationBarAppearanceDic setObject:[c copy] forKey:@"ItmColor"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"ItmColor"];
}

-(UIImage *)defaultNavigationBarBackgroundImage
{
    return [self.navigationBarAppearanceDic objectForKey:@"barImage"];
}

-(void)setDefaultNavigationBarBackgroundImage:(UIImage *)img
{
    if(img)
        [self.navigationBarAppearanceDic setObject:img forKey:@"barImage"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"barImage"];
}

-(NSDictionary *)defaultNavigationTitleTextAttributes
{
    return [[self.navigationBarAppearanceDic objectForKey:@"TitleAttr"] copy];
}

-(void)setDefaultNavigationTitleTextAttributes:(NSDictionary *)attrDic
{
    if(attrDic)
        [self.navigationBarAppearanceDic setObject:[attrDic copy] forKey:@"TitleAttr"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"TitleAttr"];
}


#pragma mark- transparent
-(void)setNavigationBarTransparent:(BOOL)transparent
{
    if(transparent == self.navigationBarTransparent)
        return;
    
    UIImage *img = nil;
    
    if(transparent)
    {
        if(!sNavigationBarTransparentImage)
        {
            CGRect rect = CGRectMake(0, 0, 1, 1);
            
            UIGraphicsBeginImageContext(rect.size);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context,[UIColor clearColor].CGColor);
            CGContextFillRect(context, rect);
            sNavigationBarTransparentImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        img = sNavigationBarTransparentImage;
    }
    [self.navigationBar _reloadBarTransparent:transparent];
    [self.navigationBar reloadBarBackgroundImage:img];
    [self.navigationBar reloadBarShadowImage:img];
}

-(BOOL)isNavigationBarTransparent
{
    if (@available(iOS 13.0, *)) {
        return [self.navigationBar rr_Transparent];
    }
    UIImage *bgImage = [self.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    return [bgImage isEqual:sNavigationBarTransparentImage];
}


#pragma mark- push/pop completion block

// ---- back up blocks
#warning 2024.05.30 Notted: On very few devices, the -mob_navigationTransitionView:didEndTransition:fromView:toView method is not called, so a backup of all blocks is made here and the execution is delayed to ensure that the blocks will be executed.\
在极少数设备上出现不会调用-mob_navigationTransitionView:didEndTransition:fromView:toView 这个方法，所以这里对所有的block做一份备份并延迟执行，以确保block会被执行。
-(void)backUpCompletionBlock:(nullable TransitionCompletionCallBackType)completion transitionAnimate:(BOOL)animated {
    NSMutableArray *mArray = objc_getAssociatedObject(self, &kNavigationBlockBckupKey);
    if(mArray == nil) {
        mArray = [NSMutableArray arrayWithCapacity:4];
        objc_setAssociatedObject(self, &kNavigationBlockBckupKey, mArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
       
        // NO NEED?
//        for (TransitionCompletionCallBackType blk in mArray) {
//            blk();
//        }
//        [mArray removeAllObjects];
    }
    
    if (completion) {
        
        [mArray addObject:completion];
        
        //注意：push/pop执行完成的时间，跟业务有关，有的时候在主线程做太多的逻辑处理，会导致这个时间更长，所以这里设置时间稍微长一点会合理，（毕竟是少数设备才会出现要延迟执行的情况，所以时间设置要大一点，否则正常设备也受影响)
        NSTimeInterval second = 0.3;
        if(animated)
            second = 1.0;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([mArray containsObject:completion]) {
                completion();
                [mArray removeObject:completion];
            }
        });
    }
}

-(void)removeBackedUpBlock:(_Nullable TransitionCompletionCallBackType)completion {
    if(!completion)
        return;
    NSMutableArray *mArray = objc_getAssociatedObject(self, &kNavigationBlockBckupKey);
#if 0
    [mArray removeObject:completion];
#else
    NSUInteger idx = [mArray indexOfObject:completion];
    if(idx != NSNotFound) {
        [mArray removeObjectAtIndex:idx];
    }
#endif
}

-(void)setCompletionBlock:(nullable TransitionCompletionCallBackType)completion
{
    objc_setAssociatedObject(self, &kNavigationCompletionBlockKey, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
// ---- end for back up blocks


//Note: 2024.05.30 This method can't grantee to be called On very few devices devices; so i added block backup and excute later mechanism \
在极少数设备上（跟系统版本没有关系）出现了不会调用这个方法的情况， 所以我新增了一个block的备份延迟执行的机制
-(void)mob_navigationTransitionView:(id)obj1 didEndTransition:(long)b fromView:(id)v1 toView:(id)v2
{
    [self mob_navigationTransitionView:obj1 didEndTransition:b fromView:v1 toView:v2];

    TransitionCompletionCallBackType cmpltBlock = objc_getAssociatedObject(self, &kNavigationCompletionBlockKey);
    
    
    if(cmpltBlock) {
        [self setCompletionBlock:nil]; //reset the block before execution
        [self removeBackedUpBlock:cmpltBlock];
        cmpltBlock();
    }

}

//-(void)setApplyGlobalConfig:(BOOL)applyGlobalConfig
//{
//    objc_setAssociatedObject(self, kNavigationControllerApplyGlobalConfigKey, [NSNumber numberWithBool:applyGlobalConfig], OBJC_ASSOCIATION_COPY_NONATOMIC);
//}
//
//-(BOOL)applyGlobalConfig
//{
//    NSNumber *boolNum = objc_getAssociatedObject(self, kNavigationControllerApplyGlobalConfigKey);
//    return boolNum.boolValue;
//}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(nullable TransitionCompletionCallBackType)completion
{
    
    [self setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
    [self backUpCompletionBlock:completion transitionAnimate:animated];
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(nullable TransitionCompletionCallBackType)completion
{
    [self setCompletionBlock:completion];
    UIViewController *vc =  [self popViewControllerAnimated:animated];
    [self backUpCompletionBlock:completion transitionAnimate:animated];
    return vc;
}

- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(nullable TransitionCompletionCallBackType)completion
{
    [self setCompletionBlock:completion];
    NSArray<__kindof UIViewController *> *vcs = [self popToViewController:viewController animated:animated];
    [self backUpCompletionBlock:completion transitionAnimate:animated];
    return vcs;
}

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated completionBlock:(nullable TransitionCompletionCallBackType)completion
{
    [self setCompletionBlock:completion];
    NSArray<__kindof UIViewController *> *vcs = [self popToRootViewControllerAnimated:animated];
    [self backUpCompletionBlock:completion transitionAnimate:animated];
    return vcs;
}




@end

const char naviagionItemStackKey = 'a';

@implementation UINavigationItem (StatusStack)

-(NSMutableArray *)statusStack
{
    NSMutableArray *stack = objc_getAssociatedObject(self, &naviagionItemStackKey);
    if(!stack)
    {
        stack = [NSMutableArray arrayWithCapacity:3];
        objc_setAssociatedObject(self, &naviagionItemStackKey, stack, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return stack;
}

-(void)popStatus
{
    NSMutableDictionary *mdic = [[self statusStack] lastObject];
    if(mdic)
    {
        self.rightBarButtonItems = [mdic objectForKey:@"rightBarButtonItems"];
        self.leftBarButtonItems = [mdic objectForKey:@"leftBarButtonItems"];
        self.backBarButtonItem = [mdic objectForKey:@"backBarButtonItem"];
        self.titleView = [mdic objectForKey:@"titleView"];
        self.title = [mdic objectForKey:@"title"];
        
        [[self statusStack] removeObject:mdic];
    }
}

-(void)pushStatus
{
    NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithCapacity:5];
    
    if(self.rightBarButtonItems)
        [mdic setObject:self.rightBarButtonItems forKey:@"rightBarButtonItems"];
    if(self.leftBarButtonItems)
        [mdic setObject:self.leftBarButtonItems forKey:@"leftBarButtonItems"];
    if(self.backBarButtonItem)
        [mdic setObject:self.backBarButtonItem forKey:@"backBarButtonItem"];
    if(self.titleView)
        [mdic setObject:self.titleView forKey:@"titleView"];
    if(self.title)
        [mdic setObject:self.title forKey:@"title"];
    
    [[self statusStack] addObject:mdic];
}

@end
