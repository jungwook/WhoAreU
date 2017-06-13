//
//  ModalAnimator.m
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 18..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ModalAnimator.h"

#pragma mark - UIViewControllerAnimatedTransitioning

@implementation PushModalAnimator

+ (instancetype) animator
{
    CGFloat scale = 0.96f;
    
    PushModalAnimator *animator = [PushModalAnimator new];
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
        backgroundView.backgroundColor = self.backgroundShadeColor;
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
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:toController];
    
    UIView* container = transitionContext.containerView;
    CGRect initialFrame = container.bounds;
    
    initialFrame.origin.y = CGRectGetHeight(initialFrame);

    UIView *backgroundView = [self backgroundForView:container];
    UIView *screenshot = [[UIApplication sharedApplication].keyWindow snapshotViewAfterScreenUpdates:NO];
    
    backgroundView.alpha = 0;
    [container addSubview:screenshot];
    [container addSubview:backgroundView];
    
    fromController.view.alpha = 0;
    fromController.view.hidden = YES;

    toController.view.frame = initialFrame;
    [container addSubview:toController.view];
    
    [UIView animateKeyframesWithDuration:0.35 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
            backgroundView.alpha = self.backgroundShadeAlpha;
            [screenshot setTransform:CGAffineTransformMakeScale(0.96f, 0.96f)];
        }];
        
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            toController.view.frame = finalFrame;
        }];
        
    } completion:^(BOOL finished) {
        //don't forget to clean up
        fromController.view.hidden = NO;
        
        //put the original stuff back in place if the user cancelled
        if(transitionContext.transitionWasCancelled)
        {
            [toController.view removeFromSuperview];
            [container addSubview:fromController.view];
        }
        
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        
    }];
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

@implementation PopModalAnimator


+ (instancetype) animator
{
    CGFloat scale = 0.96f;
    
    PopModalAnimator *animator = [PopModalAnimator new];
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
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* container = transitionContext.containerView;
    
    CGRect initialFrame = toController.view.bounds;
    initialFrame.origin.y = container.frame.size.height;
    
    UIView *backgroundView = [self backgroundForView:container];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         UIView *fsv = [container.subviews firstObject];
                         fsv.transform = CGAffineTransformIdentity;
                         fromController.view.frame = initialFrame;
                         toController.view.alpha = 1;
                         backgroundView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         toController.view.hidden = NO;
                         [backgroundView removeFromSuperview];
                         
                         if(transitionContext.transitionWasCancelled)
                         {
//                             [toController.view removeFromSuperview];
//                             [container addSubview:fromController.view];
                         }
                         
                         [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                     }];
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



