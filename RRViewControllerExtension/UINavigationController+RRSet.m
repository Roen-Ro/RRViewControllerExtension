//
//  UINavigationController+RRSet.m
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富(Roen) on.
//

#import "UINavigationController+RRSet.h"
#import <objc/runtime.h>
#import "RRViewControllerExtension.h"

static UIImage *sNavigationBarTransparentImage;

UIImage * RR_ClearImage(void) {
    if(!sNavigationBarTransparentImage) {
        CGRect rect = CGRectMake(0, 0, 1, 1);
        
        UIGraphicsBeginImageContext(rect.size);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context,[UIColor clearColor].CGColor);
        CGContextFillRect(context, rect);
        sNavigationBarTransparentImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return sNavigationBarTransparentImage;
}
/// https://github.com/QMUI/QMUIDemo_iOS/blob/master/QMUI/QMUIKit/QMUICore/QMUIRuntime.h
///targetSelector 是否在 targetClass 中
CG_INLINE BOOL
RR_HasOverrideSuperclassMethod(Class targetClass, SEL targetSelector) {
    Method method = class_getInstanceMethod(targetClass, targetSelector);
    if (!method) return NO;
    
    Method methodOfSuperclass = class_getInstanceMethod(class_getSuperclass(targetClass), targetSelector);
    if (!methodOfSuperclass) return YES;
    
    return method != methodOfSuperclass;
}
/**
 *  用 block 重写某个 class 的指定方法
 *  @param targetClass 要重写的 class
 *  @param targetSelector 要重写的 class 里的实例方法，注意如果该方法不存在于 targetClass 里，则什么都不做
 *  @param implementationBlock 该 block 必须返回一个 block，返回的 block 将被当成 targetSelector 的新实现，所以要在内部自己处理对 super 的调用，以及对当前调用方法的 self 的 class 的保护判断（因为如果 targetClass 的 targetSelector 是继承自父类的，targetClass 内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的 targetSelector，所以会产生预期之外的 class 的影响，例如 targetClass 传进来  UIButton.class，则最终可能会影响到 UIView.class），implementationBlock 的参数里第一个为你要修改的 class，也即等同于 targetClass，第二个参数为你要修改的 selector，也即等同于 targetSelector，第三个参数是一个 block，用于获取 targetSelector 原本的实现，由于 IMP 可以直接当成 C 函数调用，所以可利用它来实现“调用 super”的效果，但由于 targetSelector 的参数个数、参数类型、返回值类型，都会影响 IMP 的调用写法，所以这个调用只能由业务自己写。
 */
CG_INLINE BOOL
RR_OverrideImplementation(Class targetClass, SEL targetSelector, id (^implementationBlock)(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void))) {
    Method originMethod = class_getInstanceMethod(targetClass, targetSelector);
    IMP imp = method_getImplementation(originMethod);
    BOOL hasOverride = RR_HasOverrideSuperclassMethod(targetClass, targetSelector);
    
    // 以 block 的方式达到实时获取初始方法的 IMP 的目的，从而避免先 swizzle 了 subclass 的方法，再 swizzle superclass 的方法，会发现前者调用时不会触发后者 swizzle 后的版本的 bug。
    IMP (^originalIMPProvider)(void) = ^IMP(void) {
        IMP result = NULL;
        if (hasOverride) {
            result = imp;
        } else {
            // 如果 superclass 里依然没有实现，则会返回一个 objc_msgForward 从而触发消息转发的流程
            Class superclass = class_getSuperclass(targetClass);
            result = class_getMethodImplementation(superclass, targetSelector);
        }
        
        // 这只是一个保底，这里要返回一个空 block 保证非 nil，才能避免用小括号语法调用 block 时 crash
        // 空 block 虽然没有参数列表，但在业务那边被转换成 IMP 后就算传多个参数进来也不会 crash
        if (!result) {
            result = imp_implementationWithBlock(^(id selfObject){
                NSLog(([NSString stringWithFormat:@"%@", targetClass]), @"%@ 没有初始实现，%@\n%@", NSStringFromSelector(targetSelector), selfObject, [NSThread callStackSymbols]);
            });
        }
        
        return result;
    };
    
    if (hasOverride) {
        method_setImplementation(originMethod, imp_implementationWithBlock(implementationBlock(targetClass, targetSelector, originalIMPProvider)));
    } else {
        NSMethodSignature *methodSignature = [targetClass instanceMethodSignatureForSelector:targetSelector];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *typeString = [methodSignature performSelector:NSSelectorFromString([NSString stringWithFormat:@"_%@String", @"type"])];
#pragma clang diagnostic pop
        const char *typeEncoding = method_getTypeEncoding(originMethod) ?: typeString.UTF8String;
        class_addMethod(targetClass, targetSelector, imp_implementationWithBlock(implementationBlock(targetClass, targetSelector, originalIMPProvider)), typeEncoding);
    }
    
    return YES;
}

#pragma mark - UINavigationController (_SetupProperty)
UIKIT_EXTERN API_AVAILABLE(ios(15.0)) //NS_SWIFT_UI_ACTOR
/// 其实这些reload方法可以考虑交换Set方法来实现
@implementation UINavigationBar (_SetupProperty)

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
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// - [_UIBarBackground updateBackground]
        if (@available(iOS 15.0, *)) {
            RR_OverrideImplementation(NSClassFromString(@"_UIBarBackground"), NSSelectorFromString(@"updateBackground"), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                return ^(UIView *selfObject) {
                    
                    // call super
                    void (*originSelectorIMP)(id, SEL);
                    originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                    originSelectorIMP(selfObject, originCMD);
                    
                    if (!selfObject.superview) return;
                    
                    UIImageView *backgroundImageView1 = [selfObject valueForKey:@"_colorAndImageView1"];
                    UIImageView *backgroundImageView2 = [selfObject valueForKey:@"_colorAndImageView2"];
                    UIVisualEffectView *backgroundEffectView1 = [selfObject valueForKey:@"_effectView1"];
                    UIVisualEffectView *backgroundEffectView2 = [selfObject valueForKey:@"_effectView2"];
                    
                    // iOS 14 系统默认特性是存在 backgroundImage 则不存在其他任何背景，但如果存在 barTintColor 则磨砂 view 也可以共存。
                    // iOS 15 系统默认特性是 backgroundImage、backgroundColor、backgroundEffect 三者都可以共存，其中前两者共用 _colorAndImageView，而我们这个开关为了符合 iOS 14 的特性，仅针对 _colorAndImageView 是因为 backgroundImage 存在而出现的情况做处理。
                    BOOL hasBackgroundImage1 = backgroundImageView1 && backgroundImageView1.superview && !backgroundImageView1.hidden && backgroundImageView1.image;
                    BOOL hasBackgroundImage2 = backgroundImageView2 && backgroundImageView2.superview && !backgroundImageView2.hidden && backgroundImageView2.image;
                    BOOL shouldHideEffectView = hasBackgroundImage1 || hasBackgroundImage2;
                    if (shouldHideEffectView) {
                        backgroundEffectView1.hidden = YES;
                        backgroundEffectView2.hidden = YES;
                    } else {
                        // 把 backgroundImage 置为 nil，理应要恢复 effectView 的显示，但由于 iOS 15 里 effectView 有2个，什么时候显示哪个取决于 contentScrollView 的滚动位置，而这个位置在当前上下文里我们是无法得知的，所以先不处理了，交给系统在下一次 updateBackground 时刷新吧...
                    }
                    
                    // 虽然scrollEdgeAppearance 也被设置，但系统始终都会同时显示两份 view（一份 standard 的一份 scrollEdge 的），当你的样式是不透明时没问题，但如果存在半透明，同时显示两份 view 就会导致两个半透明的效果重叠在一起，最终肉眼看到的样式和预期是不符合的，所以会强制让其中一份 view 隐藏掉。
                    backgroundImageView2.hidden = YES;
                    backgroundEffectView2.hidden = YES;
                };
            });
        }
        
    });
}

-(void)_updateAppearanceBarActionBlock:(void (^ __nullable)(UINavigationBarAppearance *appearance))handler API_AVAILABLE(ios(15.0)) {
    if (!handler) return;
    UINavigationBarAppearance *appearance = self.standardAppearance;
    handler(appearance);
    self.standardAppearance = appearance;
    self.scrollEdgeAppearance = appearance;
}


-(void)reloadBarBackgroundImage:(nullable UIImage *)img {
    if (@available(iOS 15.0, *)) {
        [self _updateAppearanceBarActionBlock:^(UINavigationBarAppearance *appearance) {
            appearance.backgroundImage = img;
        }];
    } else {
        [self setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    }
}
-(void)reloadBarShadowImage:(nullable UIImage *)img{
    if (@available(iOS 15.0, *)) {
        [self _updateAppearanceBarActionBlock:^(UINavigationBarAppearance *appearance) {
            appearance.shadowImage = img;
            if (!img) {
                appearance.shadowImage = RR_ClearImage();
            }
        }];
    } else {
        [self setShadowImage:img];
    }
}
-(void)reloadBarBackgroundColor:(nullable UIColor *)color{
    if (@available(iOS 15.0, *)) {
        [self setRr_OrginBackgroundColor:color];
        BOOL transparent = [self rr_Transparent];
        [self _updateAppearanceBarActionBlock:^(UINavigationBarAppearance *obj) {
            if (transparent) {
                obj.backgroundColor = nil;
                obj.backgroundColor = nil;
            }else {
                obj.backgroundColor = color;
                obj.backgroundColor = color;
            }
        }];
    } else {
        [self setBarTintColor:color];
    }
}
-(void)reloadBarTitleTextAttributes:(nullable NSDictionary<NSAttributedStringKey, id>*)titleTextAttributes{
    if (@available(iOS 15.0, *)) {
        [self _updateAppearanceBarActionBlock:^(UINavigationBarAppearance *obj) {
            obj.titleTextAttributes = titleTextAttributes;
        }];
        
    } else {
        [self setTitleTextAttributes:titleTextAttributes];
    }
}

-(void)_reloadBarTransparent:(BOOL)transparent {
    if (@available(iOS 15.0, *)) {
        [self setRr_Transparent:transparent];
        
        [self _updateAppearanceBarActionBlock:^(UINavigationBarAppearance *obj) {
            if (transparent) {
                obj.backgroundEffect = nil;
                obj.backgroundEffect = nil;
            }else {
                UINavigationBarAppearance *temp = [[UINavigationBarAppearance alloc] init];
                obj.backgroundEffect = temp.backgroundEffect;
                obj.backgroundEffect = temp.backgroundEffect;
            }
        }];
        [self reloadBarBackgroundColor:[self rr_OrginBackgroundColor]];
    }
}
@end
@interface UIViewController (_RRAnimateAndCompletion)
- (void)rr_animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
                           completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion;
@end
@implementation  UIViewController (_RRAnimateAndCompletion)

- (void)rr_animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
                           completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion {
    if (self.transitionCoordinator) {
        BOOL animationQueuedToRun = [self.transitionCoordinator animateAlongsideTransition:animation completion:completion];
        // 某些情况下传给 animateAlongsideTransition 的 animation 不会被执行，这时候要自己手动调用一下
        if (!animationQueuedToRun && animation) {
            animation(nil);
        }
    } else {
        if (animation) animation(nil);
        if (completion) completion(nil);
    }
}

@end


//static char kNavigationCompletionBlockKey;
//static char kNavigationBlockBckupKey;

#pragma mark - UINavigationController + RRSet
@implementation UINavigationController (RRSet)

/// navigationTransitionView:didEndTransition:fromView:toView: 在iOS 18上彻底不执行了 换种实现方式
//+(void)initialize
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Class class = [self class];
//
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//        SEL originalSelector = @selector(navigationTransitionView:didEndTransition:fromView:toView:);
//        SEL swizzledSelector = @selector(mob_navigationTransitionView:didEndTransition:fromView:toView:);
//        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class, swizzledSelector));
//#pragma clang diagnostic pop
//
//        // for debug useage, to get the system selector message signature
//        //   NSMethodSignature *sig = [class instanceMethodSignatureForSelector:originalSelector];
//        //   NSLog(@"NSMethodSignature for originalSelector is %@",sig);
//
//    });
//}

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
//#warning 2024.05.30 Notted: On very few devices, the -mob_navigationTransitionView:didEndTransition:fromView:toView method is not called, so a backup of all blocks is made here and the execution is delayed to ensure that the blocks will be executed.\
//在极少数设备上出现不会调用-mob_navigationTransitionView:didEndTransition:fromView:toView 这个方法，所以这里对所有的block做一份备份并延迟执行，以确保block会被执行。
//-(void)backUpCompletionBlock:(nullable TransitionCompletionCallBackType)completion transitionAnimate:(BOOL)animated {
//    NSMutableArray *mArray = objc_getAssociatedObject(self, &kNavigationBlockBckupKey);
//    if(mArray == nil) {
//        mArray = [NSMutableArray arrayWithCapacity:4];
//        objc_setAssociatedObject(self, &kNavigationBlockBckupKey, mArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    } else {
//       
//        // NO NEED?
////        for (TransitionCompletionCallBackType blk in mArray) {
////            blk();
////        }
////        [mArray removeAllObjects];
//    }
//    
//    if (completion) {
//        
//        [mArray addObject:completion];
//        
//        //注意：push/pop执行完成的时间，跟业务有关，有的时候在主线程做太多的逻辑处理，会导致这个时间更长，所以这里设置时间稍微长一点会合理，（毕竟是少数设备才会出现要延迟执行的情况，所以时间设置要大一点，否则正常设备也受影响)
//        NSTimeInterval second = 0.3;
//        if(animated)
//            second = 1.0;
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if ([mArray containsObject:completion]) {
//                completion();
//                [mArray removeObject:completion];
//            }
//        });
//    }
//}
//
//-(void)removeBackedUpBlock:(_Nullable TransitionCompletionCallBackType)completion {
//    if(!completion)
//        return;
//    NSMutableArray *mArray = objc_getAssociatedObject(self, &kNavigationBlockBckupKey);
//#if 0
//    [mArray removeObject:completion];
//#else
//    NSUInteger idx = [mArray indexOfObject:completion];
//    if(idx != NSNotFound) {
//        [mArray removeObjectAtIndex:idx];
//    }
//#endif
//}
//
//-(void)setCompletionBlock:(nullable TransitionCompletionCallBackType)completion
//{
//    objc_setAssociatedObject(self, &kNavigationCompletionBlockKey, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
//}
// ---- end for back up blocks


//Note: 2024.05.30 This method can't grantee to be called On very few devices devices; so i added block backup and excute later mechanism \
在极少数设备上（跟系统版本没有关系）出现了不会调用这个方法的情况， 所以我新增了一个block的备份延迟执行的机制
//-(void)mob_navigationTransitionView:(id)obj1 didEndTransition:(long)b fromView:(id)v1 toView:(id)v2
//{
//    [self mob_navigationTransitionView:obj1 didEndTransition:b fromView:v1 toView:v2];
//
//    TransitionCompletionCallBackType cmpltBlock = objc_getAssociatedObject(self, &kNavigationCompletionBlockKey);
//    
//    
//    if(cmpltBlock) {
//        [self setCompletionBlock:nil]; //reset the block before execution
//        [self removeBackedUpBlock:cmpltBlock];
//        cmpltBlock();
//    }
//
//}

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
//    [self setCompletionBlock:completion];
    // 要先进行转场操作才能产生 self.transitionCoordinator，然后才能用 rr_animateAlongsideTransition:completion:，所以不能把转场操作放在 animation block 里。
    [self pushViewController:viewController animated:animated];
    if (completion) {
        [self rr_animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            completion();
        }];
    }
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
//    [self setCompletionBlock:completion];
//    return [self popViewControllerAnimated:animated];
    // 要先进行转场操作才能产生 self.transitionCoordinator，然后才能用 rr_animateAlongsideTransition:completion:，所以不能把转场操作放在 animation block 里。
    UIViewController *result = [self popViewControllerAnimated:animated];
    if (completion) {
        [self rr_animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            completion();
        }];
    }
    return result;
}

- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
//    [self setCompletionBlock:completion];
//    return [self popToViewController:viewController animated:animated];
    // 要先进行转场操作才能产生 self.transitionCoordinator，然后才能用 rr_animateAlongsideTransition:completion:，所以不能把转场操作放在 animation block 里。
    NSArray<UIViewController *> *result = [self popToViewController:viewController animated:animated];
    if (completion) {
        [self rr_animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            completion();
        }];
    }
    return result;
}

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
//    [self setCompletionBlock:completion];
//    return [self popToRootViewControllerAnimated:animated];
    // 要先进行转场操作才能产生 self.transitionCoordinator，然后才能用 rr_animateAlongsideTransition:completion:，所以不能把转场操作放在 animation block 里。
    NSArray<UIViewController *> *result = [self popToRootViewControllerAnimated:animated];
    if (completion) {
        [self rr_animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            completion();
        }];
    }
    return result;
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
