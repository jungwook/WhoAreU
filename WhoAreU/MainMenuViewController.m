//
//  MainMenuViewController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 19..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MainMenuViewController.h"
#import "MDCPalettes.h"
#import "MDCInkLayer.h"
#import "MDCInkView.h"

@interface MainMenuViewController ()
@property (nonatomic, strong) NSArray <UIViewController*> *viewControllers;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) UIButton *floatingActionButton;
@property (nonatomic) BOOL opened;
@property (nonatomic, readonly) CATransform3D currentTransform, menuViewTransform;
@property (nonatomic, readonly) UIView *currentView;
@property (nonatomic, readonly) CALayer *currentLayer;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) CALayer *fadingLayer;
@property (nonatomic, strong) MDCInkView *ink;
@property (nonatomic, readonly) UIBezierPath *startPath, *endPath;
@property (nonatomic, readonly) CGFloat animationDuration;
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (nonatomic) BOOL animating;
@end


@implementation MainMenuViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.maskLayer = [CAShapeLayer layer];
    self.maskLayer.path = self.endPath.CGPath;
    
    UIViewController *vc1 = [UIViewController new];
    vc1.view.backgroundColor = [MDCPalette redPalette].tint400;
    UIViewController *vc2 = [UIViewController new];
    vc2.view.backgroundColor = [MDCPalette yellowPalette].tint400;
    UIViewController *vc3 = [UIViewController new];
    vc3.view.backgroundColor = [MDCPalette bluePalette].tint400;
    self.viewControllers = @[ vc1, vc2, vc3];

    [self setupFloatingActionButton];
    self.currentViewController = self.viewControllers.firstObject;
    [self setupMenuView];
    
    self.fadingLayer = [CALayer layer];
    self.fadingLayer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:self.fadingLayer below:self.menuView.layer];
    
    self.ink = [MDCInkView new];
    self.ink.frame = self.view.bounds;
    self.ink.inkColor = self.menuView.backgroundColor;
    [self.view addSubview:self.ink];
}

- (void)setupFloatingActionButton
{
    CGFloat size = 40;
    CGRect floatingActionButtonFrame = CGRectMake(20, 340, size, size);

    self.floatingActionButton = [UIButton new];
    self.floatingActionButton.frame = floatingActionButtonFrame;
    self.floatingActionButton.backgroundColor = [MDCPalette greyPalette].tint500;
    self.floatingActionButton.radius = size / 2.f;
    self.floatingActionButton.clipsToBounds = YES;
    
    [self.view addSubview:self.floatingActionButton];
    [self.floatingActionButton addTarget:self action:@selector(tappedMenu:) forControlEvents:UIControlEventTouchDown];
}

- (void)setupMenuView
{
    self.menuView.backgroundColor = [MDCPalette greyPalette].tint600;
    self.menuView.alpha = 0;
    self.menuView.layer.transform = self.menuViewTransform;
}

- (UIBezierPath *)startPath
{
    return [UIBezierPath bezierPathWithOvalInRect:self.floatingActionButton.frame];
}

extern inline CGFloat lengthBetween(CGPoint p1, CGPoint p2)
{
    return sqrt(((p1.x - p2.x) * (p1.x - p2.x)) + ((p1.y - p2.y) * (p1.y - p2.y)));
}

- (UIBezierPath *)endPath
{
    CGPoint center = self.floatingActionButton.center;
    CGPoint frameEnd = CGPointMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    
    CGFloat radius = lengthBetween(center, frameEnd), diameter = radius*2.f;
    CGRect rect = CGRectMake(center.x - radius,
                             center.y - radius,
                             diameter,
                             diameter);
    return [UIBezierPath bezierPathWithOvalInRect:rect];
}

- (CAAnimation*) explodeAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = self.animationDuration;
    animation.fromValue = (__bridge id)self.startPath.CGPath;
    animation.toValue   = (__bridge id)self.endPath.CGPath;
    animation.removedOnCompletion = YES;
    animation.delegate = self;
    return animation;
}

- (CAAnimation*) implodeAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = self.animationDuration;
    animation.fromValue   = (__bridge id)self.endPath.CGPath;
    animation.toValue = (__bridge id)self.startPath.CGPath;
    animation.removedOnCompletion = YES;
    animation.delegate = self;
    return animation;
}

- (CAAnimation*) fadingAnimation
{
    UIColor *color = self.floatingActionButton.backgroundColor;
    UIColor *fromColor = [color colorWithAlphaComponent:0.4f];
    UIColor *toColor = [color colorWithAlphaComponent:0.f];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    animation.duration = self.animationDuration;
    animation.fromValue = (id)fromColor.CGColor;
    animation.toValue = (id)toColor.CGColor;
    animation.removedOnCompletion = YES;
    return animation;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.animating = NO;
    NSLog(@"ANIM DID STOP:%@", anim == self.explodeAnimation ? @"explode" : @"implode");
    self.maskLayer.path = self.opened ? self.endPath.CGPath : self.startPath.CGPath;
    self.menuView.alpha = self.opened;
}

- (void)animationDidStart:(CAAnimation *)anim
{
    [self.ink startTouchBeganAnimationAtPoint:self.floatingActionButton.center completion:nil];
    [self.ink startTouchEndedAnimationAtPoint:self.floatingActionButton.center completion:nil];
    self.animating = YES;
    NSLog(@"ANIM DID START:%@", anim == self.explodeAnimation ? @"explode" : @"implode");
}

- (CAAnimation*) flipOpenMenuAnimation
{
    CABasicAnimation* animation = [CABasicAnimation
                                   animationWithKeyPath:@"transform.rotation.y"];
    animation.fromValue = @(-M_PI_2);
    animation.toValue = @(0);
    animation.repeatCount = 1;
    animation.duration = 0.3f;
    
    return animation;
}

- (CAAnimation*) flipCloseMenuAnimation
{
    CABasicAnimation* animation = [CABasicAnimation
                                   animationWithKeyPath:@"transform.rotation.y"];
    animation.fromValue = @(0);
    animation.toValue = @(-M_PI_2);
    animation.repeatCount = 1;
    animation.duration = 0.3f;
    
    return animation;
}

- (IBAction)tappedMenuItem:(UIButton *)sender
{
    if (self.animating)
        return;
    NSUInteger index = sender.tag;
    self.currentViewController = [self.viewControllers objectAtIndex:index];
    self.opened = NO;
}

- (void) tappedMenu:(id)sender
{
    if (self.animating)
        return;
    
    self.opened = !self.opened;
}

- (void)setOpened:(BOOL)opened
{
    self.menuView.alpha = 1;
    
    _opened = opened;

//    self.menuView.layer.anchorPoint = CGPointMake(0, 0.5);
//    CGPoint center = self.view.center;
//    CATransform3D transform = CATransform3DIdentity;
//    transform = CATransform3DTranslate(transform, -center.x, 0, 0);
//    transform.m34 = 1.0 / 500.0;
//    self.menuView.layer.transform = transform;
    
    [self.menuView setAnchorPoint:CGPointMake(0, 0.5)];

    [UIView animateWithDuration:self.animationDuration
                          delay:0
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.3f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.currentLayer.transform = self.currentTransform;
                         self.menuView.layer.transform = self.menuViewTransform;
    } completion:nil];
    
//    [self.menuView.layer addAnimation:self.opened ? self.flipOpenMenuAnimation : self.flipCloseMenuAnimation forKey:@"rotation"];
    
//    [self.fadingLayer removeFromSuperlayer];
//    [self.view.layer insertSublayer:self.fadingLayer below:self.menuView.layer];
//
//    [self.maskLayer removeAllAnimations];
//    [self.maskLayer addAnimation:self.opened ? self.explodeAnimation : self.implodeAnimation
//                          forKey:self.opened ? @"explode" : @"implode"];
//    [self.fadingLayer addAnimation:self.fadingAnimation forKey:@"fading"];
}

- (CATransform3D) menuViewTransform
{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1/500.f;
    CGFloat angle = -M_PI_2;
    transform = CATransform3DRotate(transform, angle, 0, 1.0, 0);
//    transform = CATransform3DTranslate(transform, -self.view.center.x, 0, 0);
    return self.opened ? CATransform3DIdentity : transform;
}

- (CATransform3D) currentTransform
{
    CGFloat factor = 0.9f;
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DScale(transform, factor, factor, 1.f);
    transform = CATransform3DTranslate(transform, 400.f, 0, 0);
    
//    return CATransform3DIdentity;
    return self.opened ? transform : CATransform3DIdentity;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setCurrentViewController:(UIViewController *)currentViewController
{
    if (self.currentViewController) {
        [self.currentViewController willMoveToParentViewController:nil];
        [self.currentView removeFromSuperview];
        [self.currentViewController removeFromParentViewController];
    }
    
    _currentViewController = currentViewController;
    
    [self.currentLayer setTransform:CATransform3DIdentity];
    [self.currentView setFrame:self.view.frame];
    [self addChildViewController:self.currentViewController];
    
    ///////////
    // Inserting view under floating action button
    [self.view insertSubview:self.currentView belowSubview:self.menuView];
//    [self.view insertSubview:self.currentView belowSubview:self.floatingActionButton];
//    [self.view insertSubview:self.currentView belowSubview:self.menuView];
    ///////////
    
    [self.currentViewController didMoveToParentViewController:self];
    [self.currentLayer setTransform:self.currentTransform];
    
//    self.menuView.layer.mask = self.maskLayer;
//    self.menuView.layer.masksToBounds = YES;
}

- (UIView *)currentView
{
    return self.currentViewController.view;
}

- (CALayer *)currentLayer
{
    return self.currentView.layer;
}

- (CGFloat)animationDuration
{
    return 0.3f;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
