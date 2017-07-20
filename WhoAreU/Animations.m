//
//  Animations.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Animations.h"

@implementation Animations

+ (CGFloat)animationDuration
{
    return 0.3f;
}

+ (CAAnimation*) explodeAnimationUsingStartPath:(CGPathRef)start endPath:(CGPathRef)end delegate:(id<CAAnimationDelegate>)delegate
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration  = self.animationDuration;
    animation.fromValue = (__bridge id)start;
    animation.toValue   = (__bridge id)end;
    animation.removedOnCompletion = YES;
    animation.delegate  = delegate;
    return animation;
}

+ (CAAnimation*) implodeAnimationUsingStartPath:(CGPathRef)start endPath:(CGPathRef)end delegate:(id<CAAnimationDelegate>)delegate
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration  = self.animationDuration;
    animation.fromValue = (__bridge id) end;
    animation.toValue   = (__bridge id) start;
    animation.removedOnCompletion = YES;
    animation.delegate  = delegate;
    return animation;
}

+ (CAAnimation*) fadingAnimation:(UIColor*)tintColor
{
    UIColor *color = tintColor ?: [UIColor blackColor];
    UIColor *fromColor = [color colorWithAlphaComponent:0.4f];
    UIColor *toColor = [color colorWithAlphaComponent:0.f];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    animation.duration = self.animationDuration;
    animation.fromValue = (id)fromColor.CGColor;
    animation.toValue = (id)toColor.CGColor;
    animation.removedOnCompletion = YES;
    return animation;
}

+ (CAAnimation*) flipOpenMenuAnimation
{
    CABasicAnimation* animation = [CABasicAnimation
                                   animationWithKeyPath:@"transform.rotation.y"];
    animation.fromValue = @(-M_PI_2);
    animation.toValue = @(0);
    animation.repeatCount = 1;
    animation.duration = 0.3f;

    return animation;
}

+ (CAAnimation*) flipCloseMenuAnimation
{
    CABasicAnimation* animation = [CABasicAnimation
                                   animationWithKeyPath:@"transform.rotation.y"];
    animation.fromValue = @(0);
    animation.toValue = @(-M_PI_2);
    animation.repeatCount = 1;
    animation.duration = 0.3f;

    return animation;
}

@end
