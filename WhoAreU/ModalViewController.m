//
//  ModalViewController.m
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 19..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ModalViewController.h"
#import "ModalAnimator.h"

@interface Interactor()
@end

@implementation Interactor


@end

@interface ModalViewController ()
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) Interactor* transition;
@end

@implementation ModalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
    [self.view addGestureRecognizer:self.panGesture];
    self.transition = [Interactor new];
    
    self.transitioningDelegate = self;
    self.navigationController.delegate = self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.transition;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.transition;
}

- (void) panning:(UIPanGestureRecognizer*) gesture
{
    CGFloat percentageThreshold = 0.3;
    CGPoint translation = [gesture translationInView:self.view];
    CGFloat verticalMovement = translation.y / CGRectGetHeight(self.view.bounds);
    CGFloat downwardMovement = fmaxf((float) verticalMovement, 0.0f);
    CGFloat downwardMovementPercent = fminf((float) downwardMovement, 1.0f);
    CGFloat progress = downwardMovementPercent;
    
    // convert y-position to downward pull progress (percentage)
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
            if (verticalMovement < 0.f) {
                return;
            }
            self.transition.started = YES;
            [self dismissViewControllerAnimated:YES completion:nil];
            
            break;
        case UIGestureRecognizerStateChanged:
            self.transition.shouldFinish = (progress > percentageThreshold);
            [self.transition updateInteractiveTransition:progress];
            break;
        case UIGestureRecognizerStateCancelled:
            self.transition.started = NO;
            [self.transition cancelInteractiveTransition];
            break;
        case UIGestureRecognizerStateEnded:
            self.transition.started = NO;
            if (self.transition.shouldFinish) {
                [self.transition finishInteractiveTransition];
            }
            else {
                [self.transition cancelInteractiveTransition];
            }
            break;
        default:
            break;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    if([animationController isKindOfClass:[PopModalAnimator class]])
        return self.transition;
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    return [PushModalAnimator animator];
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    switch(operation)
    {
        case UINavigationControllerOperationPush:
            return [PushModalAnimator animator];
        case UINavigationControllerOperationPop:
            return [PopModalAnimator animator];
        default:
            return nil;
    }
}



- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [PopModalAnimator animator];
}

@end
