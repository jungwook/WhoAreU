//
//  BalloonLabel.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "BalloonLabel.h"

@interface BalloonLabel ()
@property (nonatomic) CGFloat balloonInset, cornerRadius;
@end

@implementation BalloonLabel

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.type = kBalloonTypeLeft;
        self.balloonInset = 10;
        self.cornerRadius = 8;
        self.textInsets = UIEdgeInsetsMake(5, self.balloonInset+8, 5, 8);
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    UIEdgeInsets insets = self.textInsets;
    
    [self invalidateIntrinsicContentSize];
    CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                    limitedToNumberOfLines:numberOfLines];
    
    rect.origin.x    -= insets.left;
    rect.origin.y    -= insets.top;
    rect.size.width  += (insets.left + insets.right);
    rect.size.height += (insets.top + insets.bottom);
    
    return rect;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setShape];
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (void)setShape
{
    CAShapeLayer *mask = [CAShapeLayer layer];
    
    mask.path = [self ballonPath].CGPath;
    self.layer.mask = mask;
}

- (UIBezierPath*) ballonPath
{
    const CGFloat cr = self.cornerRadius, inset = self.balloonInset;
    
    CGRect rect = self.frame;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = rect.size.width, h=rect.size.height;
    
    CGFloat s=h-5.0f;
    CGFloat p=h-5.0f;
    CGFloat e=h-12.0f;
    CGFloat f = 0.4f;
    CGFloat m = MAX(h-cr, s);
    m = s;
    
    switch (self.type) {
        case kBalloonTypeLeft:
            [path moveToPoint:CGPointMake(inset, cr)];
            [path addQuadCurveToPoint:CGPointMake(inset+cr, 0) controlPoint:CGPointMake(inset, 0)];
            [path addLineToPoint:CGPointMake(w-cr, 0)];
            [path addQuadCurveToPoint:CGPointMake(w, cr) controlPoint:CGPointMake(w, 0)];
            [path addLineToPoint:CGPointMake(w, h-cr)];
            [path addQuadCurveToPoint:CGPointMake(w-cr, h) controlPoint:CGPointMake(w, h)];
            [path addLineToPoint:CGPointMake(inset+cr, h)];
            
            [path addQuadCurveToPoint:CGPointMake(inset, m) controlPoint:CGPointMake(inset, h)];
            
            [path addLineToPoint:CGPointMake(inset, m)];
            [path addLineToPoint:CGPointMake(inset*f, p+(s-p)*f)];
            [path addQuadCurveToPoint:CGPointMake(inset*f, p-(p-e)*f) controlPoint:CGPointMake(0, p)];
            [path addLineToPoint:CGPointMake(inset, e)];
            
            [path addLineToPoint:CGPointMake(inset, cr)];
            break;
            
        default:
            [path moveToPoint:CGPointMake(0, cr)];
            [path addQuadCurveToPoint:CGPointMake(0+cr, 0) controlPoint:CGPointMake(0, 0)];
            [path addLineToPoint:CGPointMake(w-cr-inset, 0)];
            [path addQuadCurveToPoint:CGPointMake(w-inset, cr) controlPoint:CGPointMake(w-inset, 0)];
            
            [path addLineToPoint:CGPointMake(w-inset, e)];
            [path addLineToPoint:CGPointMake(w-inset*f, p-(p-e)*f)];
            [path addQuadCurveToPoint:CGPointMake(w-inset*f, p+(s-p)*f) controlPoint:CGPointMake(w, p)];
            
            [path addLineToPoint:CGPointMake(w-inset, m)];
            
            [path addLineToPoint:CGPointMake(w-inset, m)];
            
            
            [path addQuadCurveToPoint:CGPointMake(w-cr-inset, h) controlPoint:CGPointMake(w-inset, h)];
            [path addLineToPoint:CGPointMake(cr, h)];
            [path addQuadCurveToPoint:CGPointMake(0, h-cr) controlPoint:CGPointMake(0, h)];
            [path addLineToPoint:CGPointMake(0, cr)];
            break;
    }
    
    return path;
}

@end
