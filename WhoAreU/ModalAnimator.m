//
//  ModalAnimator.m
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 18..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ModalAnimator.h"

#pragma mark - UIViewControllerAnimatedTransitioning

@implementation ModalAnimator

+ (instancetype) modalAnimatorPresenting:(BOOL)isPresenting
{
    CGFloat scale = 0.96f;
    
    ModalAnimator *animator = [ModalAnimator new];
    animator.presenting = isPresenting;
    animator.animationSpeed = 0.25f;
    animator.backgroundShadeColor = [UIColor blackColor];
    animator.scaleTransform = CGAffineTransformMakeScale(scale, scale);
    animator.springDamping = 0.88;
    animator.springVelocity = 1;
    animator.backgroundShadeAlpha = 0.4;
    return animator;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return self.animationSpeed;
}

- (UIView*)backgroundForView:(UIView*)container
{
    UIView* backgroundView = [container viewWithTag:1199];
    if(!backgroundView){
        backgroundView = [UIView new];
        backgroundView.frame = container.bounds;
        backgroundView.alpha = 0;
        backgroundView.tag = 1199;
        backgroundView.backgroundColor = _backgroundShadeColor;
    }
    return backgroundView;
}

- (UIView *)imageViewWithImage:(UIImage*)image
{
    UIView *ret = [UIView new];
    ret.layer.contents = (id) image.CGImage;
    ret.layer.contentsGravity = kCAGravityResizeAspectFill;
    
    ret.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    return ret;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    CGFloat toOffset = 0, fromOffset = 0;
    
    UIViewController <ModalDelegate> *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController <ModalDelegate> *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* container = transitionContext.containerView;

    if ([toVC respondsToSelector:@selector(offsetHeight)]) {
        toOffset = toVC.offsetHeight;
    }

    if ([fromVC respondsToSelector:@selector(offsetHeight)]) {
        fromOffset = fromVC.offsetHeight;
    }

    CGRect finalFrame = CGRectMake(0,
                            toOffset,
                            CGRectGetWidth(toVC.view.bounds),
                            CGRectGetHeight(toVC.view.bounds)-toOffset);
    
    CGRect initialFrame = toVC.view.bounds;
    initialFrame.origin.y = container.frame.size.height;
    
    UIView *backgroundView = [self backgroundForView:container];
    
    if (self.presenting)
    {
        container.backgroundColor = [UIColor darkGrayColor];
        UIView *screenshot = [[UIApplication sharedApplication].keyWindow snapshotViewAfterScreenUpdates:NO];
        [container insertSubview:screenshot atIndex:0];
        screenshot.radius = 4.0f;
        screenshot.clipsToBounds = YES;
        
        fromVC.view.alpha = 0;
        fromVC.view.hidden = YES;
        
        [container insertSubview:backgroundView belowSubview:toVC.view];
        
        toVC.view.frame = initialFrame;
        [container addSubview:toVC.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]+0.2f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             backgroundView.alpha = _backgroundShadeAlpha;
                             [screenshot setTransform:CGAffineTransformTranslate(_scaleTransform, 0 ,-fromOffset)];
                         } completion:nil];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0.2
             usingSpringWithDamping:_springDamping
              initialSpringVelocity:_springVelocity
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             toVC.view.frame = finalFrame;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
    else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             UIView *fsv = [container.subviews firstObject];
                             fsv.transform = CGAffineTransformIdentity;
                             fromVC.view.frame = initialFrame;
                             toVC.view.alpha = 1;
                             backgroundView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             toVC.view.hidden = NO;
                             [transitionContext completeTransition:YES];
                             [backgroundView removeFromSuperview];
                         }];
    }
}

- (UIImage*)rootImage
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, screenRect);
    // grab reference to our window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    // transfer content into our context
    [window.layer renderInContext:ctx];
    UIImage *screengrab = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screengrab;
}

- (UIImage*)viewAsImage:(UIView*)view
{
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end


