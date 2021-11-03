//
//  UINavigationController+RRSet.m
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富(Roen) on.
//

#import "UINavigationController+RRSet.h"
#import <objc/runtime.h>

#pragma mark - UINavigationController (_SetupProperty)
UIKIT_EXTERN API_AVAILABLE(ios(13.0), tvos(13.0)) NS_SWIFT_UI_ACTOR
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

#define kNavigationCompletionBlockKey @"completionBlk"
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

-(void)setCompletionBlock:(void (^ __nullable)(void))completion
{
    objc_setAssociatedObject(self, kNavigationCompletionBlockKey, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(void)mob_navigationTransitionView:(id)obj1 didEndTransition:(long)b fromView:(id)v1 toView:(id)v2
{
    [self mob_navigationTransitionView:obj1 didEndTransition:b fromView:v1 toView:v2];

    void (^ cmpltBlock)(void) = objc_getAssociatedObject(self, kNavigationCompletionBlockKey);
    if(cmpltBlock)
        cmpltBlock();

    [self setCompletionBlock:nil];
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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popViewControllerAnimated:animated];
}

- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popToViewController:viewController animated:animated];
}

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popToRootViewControllerAnimated:animated];
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
