# [RRUIViewControllerExtension](https://github.com/Roen-Ro/RRViewControllerExtension)


A lightweight UIViewController category extension for UINavigation  appearance management, view controller push/pop/dismiss management, memory leak detection and other convenient property and methods. Benefits include:

- Manage navigation bar appearance gracefully
- Automatic viewController memory leak detection with out any code modification.
- Push/pop with completion block call back block
- UIViewController life cycle method hook
- Other convenient properties

Reference to [this demo](https://github.com/Roen-Ro/RRViewControllerExtension) on github

## Usage

### Navigation appearance management
make specific navigation bar appearance specific for each viewcontroller staticly or dynamicly

```objective-c
//override any of the methods below in your viewcontroller's .m file to make specific navigation bar appearance

-(BOOL)prefersNavigationBarHidden;
-(BOOL)prefersNavigationBarTransparent;

-(nullable UIColor *)preferredNavatationBarColor;
-(nullable UIColor *)preferredNavigationItemColor;
-(nullable UIImage *)preferredNavigationBarBackgroundImage;
-(nullable NSDictionary *)preferredNavigationTitleTextAttributes;
```
make navigation bar appearance dynamic change, call `[self updateNavigationAppearance:YES];`  in your viewcontroller's .m file to force the update

```objective-c

    //typically in your UIScrollViewDelegate method
    - (void)scrollViewDidScroll:(UIScrollView *)scrollView
    {
        BOOL mode;
        if(scrollView.contentOffset.y > 300)
            mode = NO;
        else
            mode = YES;

        if(mode != _previewMode)
        {
            _previewMode = mode;

            //force navigation appearance update
            [self updateNavigationAppearance:YES];
        }
    }
    
    -(BOOL)prefersNavigationBarTransparent
    {
        if(_previewMode)
            return NO;
        else
            return YES;
    }
    
    -(nullable UIColor *)preferredNavigationItemColor
    {
        if(_previewMode)
            return [UIColor whiteColor];
        else
            return [UIColor blackColor];;
    }

```


you should specify default navigation bar appearance by using `[[UINavigationBar appearance] setXXX:]` right after the app launch

```objective-c

[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0 green:0.45 blue:0.8 alpha:1.0]];
[[UINavigationBar appearance] setTintColor:[UIColor redColor]];
NSDictionary * dict = [NSDictionary dictionaryWithObject:[UIColor yellowColor] forKey:NSForegroundColorAttributeName];
[[UINavigationBar appearance] setTitleTextAttributes:dict];

```
### Memory leak detection
to detect memory leak on runtime for viewcontrollers, all you have to do is just import the  `RRUIViewControllerExtension` to your project. whenever a memory leak happened, there will be a alert show on your app.
![](https://github.com/Roen-Ro/DemoResources/blob/master/RRUIViewControllerExtensio/memLeak01.png)

you can also spcify which class of  `UIViewController` or more precisely on which   `UIViewController` instance you want to do the memory leak detection by reference to methods below in `UIViewController+RRExtension.h`

```objective-c
//Unavailable in release mode. \
in debug mode, defalut is NO for classes returned from +memoryLeakDetectionExcludedClasses method and YES for others
@property (nonatomic,getter = memoryLeakDetectionEnabled) BOOL enabledMemoryLeakDetection;

//read and add or remove values from the returned set to change default excluded memory detection classes
+(NSMutableSet<NSString *> *)memoryLeakDetectionExcludedClasses;

//for subclass to override
-(void)didReceiveMemoryLeakWarning;

```


### viewController life cylcle hook
hook any of the `UIViewController` life cycylcle method before or after execution, for instacne if you want to track the user page viewing behavior, you just need to write code in your `AppDelgate.m` like:

```objective-c

//log the user enter page behavior
[UIViewController hookLifecycle:RRViewControllerLifeCycleViewWillAppear
                       onTiming:RRMethodInsertTimingBefore
                      withBlock:^(UIViewController * _Nonnull viewController, BOOL animated) {

                        [MyLog logEnterPage:NSStringFromClass([viewController class])];
                    }];
            
            
//log the user leaving page behavior
[UIViewController hookLifecycle:RRViewControllerLifeCycleViewDidDisappear
                       onTiming:RRMethodInsertTimingAfter
                      withBlock:^(UIViewController * _Nonnull viewController, BOOL animated) {

                        [MyLog logLeavePage:NSStringFromClass([viewController class])];
                    }];

```


## Author

Roen, zxllf23@163.com

## Licenses

All source code is licensed under the MIT License
