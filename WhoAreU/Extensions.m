//
//  Extensions.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <objc/runtime.h>
#import "Extensions.h"

@implementation UIView(RoundCorners)
@dynamic radius, borderColor;

-(void) setRadius:(CGFloat)radius
{
    self.layer.cornerRadius = radius;
}

-(CGFloat) radius
{
    return self.layer.cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

@end


@implementation UILabel(Shadow)
@dynamic shadow;

- (void)setShadow:(BOOL)shadow
{
    if (shadow) {
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.4;
    }
    else {
        self.layer.shadowColor = nil;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 0;
        self.layer.shadowOpacity = 0;
    }
}

- (BOOL)shadow
{
    return (BOOL) self.layer.shadowColor;
}

@end
