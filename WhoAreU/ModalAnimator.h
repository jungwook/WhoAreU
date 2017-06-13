//
//  ModalAnimator.h
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 18..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushModalAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) NSTimeInterval animationSpeed;
@property (nonatomic, strong) UIColor *backgroundShadeColor;
@property (nonatomic, assign) CGAffineTransform scaleTransform;
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat springVelocity;
@property (nonatomic, assign) CGFloat backgroundShadeAlpha;
+ (instancetype) animator;
@end

@interface PopModalAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) NSTimeInterval animationSpeed;
@property (nonatomic, strong) UIColor *backgroundShadeColor;
@property (nonatomic, assign) CGAffineTransform scaleTransform;
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat springVelocity;
@property (nonatomic, assign) CGFloat backgroundShadeAlpha;
+ (instancetype) animator;
@end

