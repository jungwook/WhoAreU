//
//  Animations.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface Animations : CAAnimation
+ (CAAnimation*) explodeAnimationUsingStartPath:(CGPathRef)start
                                        endPath:(CGPathRef)end
                                       delegate:(id<CAAnimationDelegate>)delegate;
+ (CAAnimation*) implodeAnimationUsingStartPath:(CGPathRef)start
                                        endPath:(CGPathRef)end
                                       delegate:(id<CAAnimationDelegate>)delegate;
+ (CAAnimation*) fadingAnimation:(UIColor*)tintColor;
+ (CAAnimation*) flipCloseMenuAnimation;
+ (CAAnimation*) flipOpenMenuAnimation;
+ (CGFloat) animationDuration;
@end
