//
//  HeaderMenu.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "HeaderMenu.h"

@interface HeaderMenu()
{
    CGFloat contentOffset, originalTopInset;
}
@property (nonatomic) UIEdgeInsets customViewInsets;
@property (nonatomic, strong) UIView* customView;
@property (nonatomic, readonly) CGFloat height, width, fractionRevealed, normalizedSwipe, swipedown, swipeup;
@property (nonatomic, readonly) BOOL revealed;
@property (nonatomic, readonly) UIScrollView* scrollView;
@end

@implementation HeaderMenu

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariablesWithHeight:64];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariablesWithHeight:64];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariablesWithHeight:frame.size.height];
    }
    return self;
}

+(instancetype)menuWithTabBarItems:(NSArray<NSDictionary *> *)items
{
    TabBar *bar = [TabBar new];
    
    HeaderMenu *menu = [HeaderMenu menuWithView:bar];
    menu.bar = bar;
    menu.customViewInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    bar.items = items;
    bar.gradientOn = NO;
    bar.equalWidth = YES;
    bar.blurOn = NO;
    bar.position = kTabBarIndicatorPositionNone;
    bar.selectAction = ^(NSUInteger index) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [menu openMenu:NO];
        });
        if (menu.selectAction) {
            menu.selectAction(index);
        }
    };
    
    return menu;
}

- (void)setupVariablesWithHeight:(CGFloat)height
{
    originalTopInset = -1;
    self.alpha = 0.0f;
    self.frame = CGRectMake(0, -height, CGRectGetWidth(mainWindow.bounds), height);
}

+ (instancetype) menuWithView:(UIView*)view
{
    HeaderMenu *menu = [[HeaderMenu alloc] initWithFrame:view.bounds];
    menu.customView = view;
    return menu;
}

- (CGFloat)height
{
    return CGRectGetHeight(self.bounds);
}

- (CGFloat)width
{
    return CGRectGetWidth(self.bounds);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.customView.frame = CGRectMake(self.customViewInsets.left,
                                       self.customViewInsets.top,
                                       CGRectGetWidth(self.bounds)-self.customViewInsets.left-self.customViewInsets.right,
                                       CGRectGetHeight(self.bounds)-self.customViewInsets.top-self.customViewInsets.bottom);
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview == nil) {
        UIScrollView *view = (UIScrollView*) self.superview;
        
        [view.panGestureRecognizer removeTarget:self action:@selector(panning:)];
        [view removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    // self.scrollView just became superview
    
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentOffset];
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(panning:)];
    [self.scrollView sendSubviewToBack:self];

    self.alpha = 1.0f;
    self.frame = CGRectMake(0, -self.height, CGRectGetWidth(self.scrollView.bounds), self.height);
    
    [self setupCustomView];
    [self setNeedsLayout];
}

- (void)setupCustomView
{
    self.customView.layer.anchorPoint = CGPointMake(0.5, 1);
    [self addSubview:self.customView];
}

- (UIScrollView*)scrollView
{
    return (id) self.superview;
}

- (void) panning:(UIPanGestureRecognizer*)gesture
{
    static BOOL triggerOpen = NO;
    static BOOL triggerClose = NO;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            if (originalTopInset == -1) {
                originalTopInset = self.scrollView.contentInset.top;
            }
            break;

        case UIGestureRecognizerStateEnded: {
            if (triggerOpen && !self.revealed) {
                [self openMenu:YES];
                triggerOpen = NO;
            }
            if (triggerClose && self.revealed) {
                [self openMenu:NO];
                triggerClose = NO;
            }
            break;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            triggerOpen = (self.normalizedSwipe>0);
            triggerClose = !triggerOpen;
        }
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStatePossible:
            break;
    }
}

- (CGFloat)normalizedSwipe
{
    return self.swipedown-self.swipeup;
}

- (void)openMenu:(BOOL)open
{
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(originalTopInset + open*self.height, 0, 0, 0);
    }];
}

- (BOOL)revealed
{
    return (self.scrollView.contentInset.top == originalTopInset + self.height);
}

- (CGFloat)swipedown
{
    return MAX(MIN(-self.scrollView.normalizedOffset.y / self.height, 1.0), 0);
}

- (CGFloat)swipeup
{
    return (self.scrollView.normalizedOffset.y > self.height ? 0 : MAX(MIN(self.scrollView.normalizedOffset.y / self.height, 1.0), 0));
}

- (CGFloat)fractionRevealed
{
    return self.revealed ? 1-MAX(-self.normalizedSwipe, 0) : self.swipedown;
}

- (CATransform3D)transform:(CGFloat)progress
{
    CGFloat angle = (1-progress) * M_PI_2;

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 /500.f;
    return CATransform3DRotate(transform, angle, 1.0, 0, 0);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (context == &contentOffset) {
        self.layer.transform = [self transform:self.fractionRevealed];
//        UICollectionView *cv = object;
//        NSLog(@"normalized:%@-%@", NSStringFromCGPoint(cv.contentOffset), NSStringFromUIEdgeInsets(cv.contentInset));
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
