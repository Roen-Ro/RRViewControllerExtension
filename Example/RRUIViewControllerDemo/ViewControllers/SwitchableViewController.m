//
//  SwitchableViewController.m
//  2bulu-QuanZi
//
//  Created by 罗亮富 on 14-8-14.
//  Copyright (c) 2014年 Lolaage. All rights reserved.
//

#import "SwitchableViewController.h"


@interface SwitchableViewController ()
@property (nonatomic, weak)  UIViewController *currentVc;
@end

@implementation SwitchableViewController
{
    UISegmentedControl *_segmentControl;
    UIView *_segSuperView;
    
    BOOL _isInTransition;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithViewControllers:(NSArray *)viewControllers
{
    self = [super init];
    _viewControllers = [viewControllers copy];
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUInteger count = _viewControllers.count;
    self.view.backgroundColor = [UIColor whiteColor];
    NSMutableArray *items = [NSMutableArray array];
    for(int i=0; i<count; i++)
    {
        UIViewController *vc = [_viewControllers objectAtIndex:i];
        if(!vc.title)
            vc.title = @"";
        [items addObject:vc.title];
        
#warning addChildViewController:里面会调用willMoveToParentViewController:所以下面这行代码没必要
        //  [vc willMoveToParentViewController:self];
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }
    
    _segmentControl = [[UISegmentedControl alloc]initWithItems:items];
    [_segmentControl addTarget:self action:@selector(switchChildViewControllers:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _segmentControl;
    
    if(_displayViewControllerIndex>=_viewControllers.count)
        _displayViewControllerIndex = _viewControllers.count-1;
    _segmentControl.selectedSegmentIndex = _displayViewControllerIndex;
    UIViewController *vc = [_viewControllers objectAtIndex:_segmentControl.selectedSegmentIndex];
    if(!vc.isViewLoaded)
        vc.view.frame = self.view.bounds;
    vc.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self willSwitchFromViewController:nil toViewController:vc];
    [self.view addSubview:vc.view];
    _currentVc = vc;
    [self didSwitchFromViewController:nil toViewController:vc];
    
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
//    _segmentControl.frame = CGRectMake(0, 0, self.view.frame.size.width*0.67, 30);
    
    CGRect frame = _segmentControl.frame;
    frame.size.width = self.view.frame.size.width*0.67;
    frame.origin.x = (_segmentControl.superview.frame.size.width - frame.size.width) * 0.5;
    _segmentControl.frame = frame;
}


-(void)setDisplayViewControllerIndex:(NSUInteger)displayViewControllerIndex
{
    _displayViewControllerIndex = displayViewControllerIndex;
    _segmentControl.selectedSegmentIndex = _displayViewControllerIndex;
    if(self.isViewLoaded && _displayViewControllerIndex < _viewControllers.count)
    {
        UIViewController *vc = [_viewControllers objectAtIndex:_displayViewControllerIndex];
        [self switchToViewController:vc];
    }
    
}


-(UISegmentedControl *)segmentControl
{
    return _segmentControl;
}


-(UIViewController *)currentViewController
{
    return _currentVc;
}

-(BOOL)switchToViewController:(UIViewController *)viewController
{
    if(!viewController || self.currentViewController == viewController)
        return NO;
    
    BOOL canSwitch = YES;
    if(_delegate && [_delegate respondsToSelector:@selector(switchableView:shouldSwitchToViewController:atIndex:)])
        canSwitch = [_delegate switchableView:self shouldSwitchToViewController:viewController atIndex:index];
    
    if(canSwitch)
    {
        return [self transationToViewController:viewController];
    }
    else
    {
        _segmentControl.selectedSegmentIndex = _displayViewControllerIndex;
        return NO;
    }
    
}

-(void)willSwitchFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
{
    //do nothing for subclass implement
}

-(void)didSwitchFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;
{
    self.navigationItem.leftBarButtonItems = toViewController.navigationItem.leftBarButtonItems;
    self.navigationItem.rightBarButtonItems = toViewController.navigationItem.rightBarButtonItems;
    
    if(_delegate && [_delegate respondsToSelector:@selector(switchableView:didSwitchToViewController:atIndex:)])
    {
        [_delegate switchableView:self didSwitchToViewController:toViewController atIndex:_segmentControl.selectedSegmentIndex];
    }
}

//for internal use
-(BOOL)transationToViewController:(UIViewController *)toVC
{
    if(toVC==_currentVc)
        return NO;
    
    if(!toVC.isViewLoaded)
    {
        toVC.view.frame = self.view.bounds;
        toVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    
    //    //是否向左切换
    //    BOOL isToLeft = [_viewControllers indexOfObject:_currentVc] < [_viewControllers indexOfObject:toVC];
    //    CGFloat cx;
    //    if(isToLeft)
    //    {
    //        cx = -self.view.frame.size.width/2;
    //        toVC.view.frame = CGRectMake(self.view.frame.size.width, 0, vcSize.width,vcSize.height);
    //    }
    //    else
    //    {
    //        cx = self.view.frame.size.width/2+self.view.frame.size.width;
    //        toVC.view.frame = CGRectMake(-self.view.frame.size.width, 0, vcSize.width,vcSize.height);
    //    }
    
    
    
    _isInTransition = YES;
    [self willSwitchFromViewController:_currentVc toViewController:toVC];
#if 1
    toVC.view.alpha = 0.0;
    //  [self.view addSubview:toVC.view];//no need
    _displayViewControllerIndex = [_viewControllers indexOfObject:toVC];
    [self transitionFromViewController:_currentVc
                      toViewController:toVC duration:0.25
                               options:UIViewAnimationOptionCurveLinear
                            animations:^{
                                _currentVc.view.alpha = 0.0;
                                toVC.view.alpha = 1.0;
                            }
                            completion:^(BOOL finished)
     {
         if(finished)
         {
             // [_currentVc.view removeFromSuperview];//no need];
             UIViewController *vc = _currentVc;
             _currentVc = toVC;
             [self didSwitchFromViewController:vc toViewController:toVC];
         }
         _isInTransition = NO;
         
     }];
#else
    [self.view addSubview:toVC.view];
    [_currentVc.view removeFromSuperview];
    _currentVc = toVC;
    _isInTransition = NO;
#endif
    
    
    return YES;
}

-(void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    if(parent == nil)
    {
        [_currentVc willMoveToParentViewController:nil];
    }
}

-(void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    if(parent == nil)
    {
        [_currentVc didMoveToParentViewController:nil];
    }
}

-(BOOL)switchChildViewControllers:(UISegmentedControl *)seg
{
    if (_isInTransition)
        return NO;
    
    UIViewController *toVC = [_viewControllers objectAtIndex:seg.selectedSegmentIndex];
    return [self switchToViewController:toVC];
}

//-(void)swipeRight:(UISwipeGestureRecognizer *)swp
//{
//    if(_segmentControl.selectedSegmentIndex>0)
//    {
//        _segmentControl.selectedSegmentIndex -= 1;
//        if(![self switchChildViewControllers:_segmentControl])
//            _segmentControl.selectedSegmentIndex += 1;
//    }
//}
//
//-(void)swipeLeft:(UISwipeGestureRecognizer *)swp
//{
//    if(_segmentControl.selectedSegmentIndex<_viewControllers.count-1)
//    {
//        _segmentControl.selectedSegmentIndex += 1;
//        if(![self switchChildViewControllers:_segmentControl])
//            _segmentControl.selectedSegmentIndex -= 1;
//    }
//}




@end


