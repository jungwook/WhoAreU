//
//  PopupView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PopupView.h"

@interface PopupView()
@property (nonatomic, readonly) CGFloat inset, maxWidth, width, height, iconSize, pointerHeight, cornerRadius, headerHeight;
@property (nonatomic) PopupViewDirection direction, pointerPosition;
@property (nonatomic, strong) UIView* menuView, *screenView, *shadowView;
@property (nonatomic, copy) VoidBlock endHandler;
@end

@implementation PopupView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void) setupVariables
{
    self.font = [UIFont systemFontOfSize:10 weight:UIFontWeightRegular];
    self.headerFont = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _headerHeight = 30.0f;
    _inset = 8.0f;
    _maxWidth = 200.0f;
    _iconSize = 20.0f;
    _pointerHeight = 5.0f;
    _direction = kPopupViewDirectionDown;
    _cornerRadius = 8.0f;
    
    self.menuView = [UIView new];
    self.menuView.backgroundColor = [UIColor whiteColor];
    
    self.shadowView = [UIView new];
    self.shadowView.backgroundColor = [UIColor clearColor];
    
    self.menuView.clipsToBounds = YES;
    [self.menuView addSubview:self.view];
    
    [self addSubview:self.shadowView];
    [self.shadowView addSubview:self.menuView];
}

- (void)setView:(UIView *)view
{
    _view = view;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = self.menuPath.CGPath;
    
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    
    self.shadowView.frame = self.bounds;
    self.menuView.frame = self.bounds;
    self.menuView.layer.mask = mask;
    
    self.view.frame = self.direction == kPopupViewDirectionDown ? CGRectMake(0, self.pointerHeight, w, h-self.pointerHeight) :
    CGRectMake(0, 0, w, h-self.pointerHeight);
    
    self.shadowView.layer.shadowPath = self.menuPath.CGPath;
    self.shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    self.shadowView.layer.shadowRadius = 1.0f;
    self.shadowView.layer.shadowOpacity = 0.6f;
}

- (CGFloat)height
{
    return CGRectGetHeight(self.view.frame);
}

- (CGFloat)width
{
    return CGRectGetWidth(self.view.frame);
}

+ (void) showFromFrame:(CGRect)frame
                  view:(UIView *)view
                   end:(VoidBlock)handler
{
    PopupView *menu = [PopupView new];
    menu.endHandler = handler;
    menu.view = view;
    [menu showFromFrame:frame];
}

+ (void) showFromView:(id)sender
                 view:(UIView *)view
                  end:(VoidBlock)handler
{
    PopupView *menu = [PopupView new];
    menu.endHandler = handler;
    menu.view = view;
    [menu showFromView:sender];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:identifierCellContent]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void) killThisView:(VoidBlock)handler
{
    CGPoint anchorPoint = CGPointMake(self.pointerPosition/self.width, 0);
    self.transform = CGAffineTransformIdentity;
    [self setAnchorPoint:anchorPoint forView:self];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.001, 0.001);
        self.screenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.2 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.screenView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.menuView removeFromSuperview];
            [self.shadowView removeFromSuperview];
            [self removeFromSuperview];
            [self.screenView removeFromSuperview];
            if (handler) {
                handler();
            }
        }];
    }];
}

- (void) tappedOutside
{
    if (self.endHandler) {
        self.endHandler();
    }
    [self killThisView:nil];
}

- (void) showFromView:(id)sender
{
    if ([sender isKindOfClass:[UIView class]]) {
        [self showFromFrame:((UIView*)sender).frame];
    }
    else if ([sender isKindOfClass:[UIEvent class]]) {
        UIEvent *event = sender;
        [self showFromFrame:[event.allTouches.anyObject view].frame];
    }
    else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIView *view = (UIView *)[sender performSelector:@selector(view)];
        [self showFromFrame:view.frame];
    }
    else {
        NSLog(identifierErrorMessage);
        return;
    }
}

- (void) showFromFrame:(CGRect)rect
{
    self.screenView = [UIView new];
    self.screenView.frame = mainWindow.bounds;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    tap.delegate = self;
    [self.screenView addGestureRecognizer:tap];
    
    [mainWindow addSubview:self.screenView];
    [self positionMenuViewOnScreen:rect];
    
    CGPoint anchorPoint = CGPointMake(self.pointerPosition/self.width, 0);
    self.shadowView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [self setAnchorPoint:anchorPoint forView:self.shadowView];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.shadowView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        self.screenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
    } completion:nil];
}

- (void) positionMenuViewOnScreen:(CGRect)rect
{
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGFloat screenWidth = CGRectGetWidth(mainWindow.bounds);
    CGFloat screenHeight = CGRectGetHeight(mainWindow.bounds);
    CGFloat statusBar = 20.0f;
    
    CGFloat midScreenX = CGRectGetMidX(mainWindow.bounds), midScreenY = CGRectGetMidY(mainWindow.bounds);
    
    self.direction = midY > midScreenY ? kPopupViewDirectionUp : kPopupViewDirectionDown;
    
    CGFloat left, right, top, bottom;
    if (midY > midScreenY) {
        bottom = minY;
        top = MAX( minY - self.height - self.pointerHeight, self.inset);
    }
    else {
        top = maxY+statusBar;
        bottom = MIN(maxY + self.height+self.pointerHeight+statusBar, screenHeight-self.inset);
    }
    
    if (midX > midScreenX) {
        right = MIN( midX + self.width / 2.0f, screenWidth - self.inset);
        left = right - self.width;
    }
    else {
        left = MAX(midX - self.width / 2.0f, self.inset);
    }
    
    self.pointerPosition = midX - left;
    self.frame = CGRectMake(left, top, self.width, bottom-top);
    [self.screenView addSubview:self];
    [self setNeedsLayout];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#define PM(__X__, __Y__) CGPointMake(__X__, __Y__)

- (UIBezierPath*) menuPath
{
    CGFloat hph = self.pointerHeight * 3.0 / 3.0f;
    CGFloat ph = self.pointerHeight;
    CGFloat h = self.height;
    CGFloat w = self.width;
    CGFloat c = self.cornerRadius;
    CGFloat m = self.pointerPosition;
    
    UIBezierPath *path = [UIBezierPath new];
    
    switch (self.direction) {
        case kPopupViewDirectionDown:
            [path moveToPoint:PM(0, ph+c)];
            [path addQuadCurveToPoint:PM(c, ph) controlPoint:PM(0, ph)];
            [path addLineToPoint:PM(m-hph, ph)];
            [path addLineToPoint:PM(m, 0)];
            [path addLineToPoint:PM(m+hph, ph)];
            [path addLineToPoint:PM(w-c, ph)];
            [path addQuadCurveToPoint:PM(w, ph+c) controlPoint:PM(w, ph)];
            [path addLineToPoint:PM(w, ph+h-c)];
            [path addQuadCurveToPoint:PM(w-c, ph+h) controlPoint:PM(w, ph+h)];
            [path addLineToPoint:PM(c, ph+h)];
            [path addQuadCurveToPoint:PM(0, ph+h-c) controlPoint:PM(0, ph+h)];
            [path addLineToPoint:PM(0, ph+c)];
            break;
            
        default:
        case kPopupViewDirectionUp:
            [path moveToPoint:PM(0, c)];
            [path addQuadCurveToPoint:PM(c, 0) controlPoint:PM(0, 0)];
            [path addLineToPoint:PM(w-c,0)];
            [path addQuadCurveToPoint:PM(w, c) controlPoint:PM(w, 0)];
            [path addLineToPoint:PM(w, h-c)];
            [path addQuadCurveToPoint:PM(w-c, h) controlPoint:PM(w, h)];
            [path addLineToPoint:PM(m+hph, h)];
            [path addLineToPoint:PM(m, h+ph)];
            [path addLineToPoint:PM(m-hph, h)];
            [path addLineToPoint:PM(c, h)];
            [path addQuadCurveToPoint:PM(0, h-c) controlPoint:PM(0, h)];
            [path addLineToPoint:PM(0, c)];
            break;
    }
    
    return path;
}

#undef PM

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.menuView.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor
{
    return self.menuView.backgroundColor;
}

@end
