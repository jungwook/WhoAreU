//
//  ModalAnimator.h
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 18..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOffsetFromTop 0

@protocol ModalDelegate <NSObject>
- (CGFloat) offsetHeight;
@end

@interface ModalAnimator : NSObject <UIViewControllerAnimatedTransitioning>

+ (instancetype) modalAnimatorPresenting:(BOOL)isPresenting;

/**
 A switch to determine if the modal is a presenter or a dismisser
 */
@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

/**
 The speed at which the semi modal appears
 */
@property (nonatomic, assign) NSTimeInterval animationSpeed;

/**
 The background shade color.
 */
@property (nonatomic, strong) UIColor *backgroundShadeColor;

/**
 The transform that gets applied to the view controller underneath the semi modal
 */
@property (nonatomic, assign) CGAffineTransform scaleTransform;

/**
 Spring damping for the semi modal transition
 */
@property (nonatomic, assign) CGFloat springDamping;

/**
 Spring Velocity for the semi modal transition
 */
@property (nonatomic, assign) CGFloat springVelocity;

/**
 The background shade alpha of the view underneath the semi modal
 */
@property (nonatomic, assign) CGFloat backgroundShadeAlpha;


@end
