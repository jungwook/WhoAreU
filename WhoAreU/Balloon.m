//
//  Balloon.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 31..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Balloon.h"

@interface Balloon()
@property (nonatomic, strong) UIFont *font;

@end

@implementation Balloon

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)setIsMine:(BOOL)isMine
{
    _isMine = isMine;
    
    self.backgroundColor = isMine ?
    kAppColor :
    [UIColor colorWithRed:110/255.f green:200/255.f blue:41/255.f alpha:1];
}

- (void)layoutSubviews
{
    [self setMask];
}

- (void) setMask
{
    const CGFloat is = 2, inset = 6;
    CGRect rect = self.frame;
    CAShapeLayer *hexagonMask = [CAShapeLayer layer];
    UIBezierPath *hexagonPath = [UIBezierPath bezierPath];
    CGFloat w = rect.size.width, h=rect.size.height;
    
    const CGPoint points[] = {
        self.isMine ? CGPointMake(0, is) :          CGPointMake(inset, is),
        self.isMine ? CGPointMake(is, 0) :          CGPointMake(inset+is, 0),
        self.isMine ? CGPointMake(w-is-inset, 0) :  CGPointMake(w-is, 0),
        self.isMine ? CGPointMake(w-inset, is) :    CGPointMake(w, is),
        self.isMine ? CGPointMake(w-inset, h-inset) :  CGPointMake(w, h-is),
        self.isMine ? CGPointMake(w, h) :           CGPointMake(w-is, h),
        self.isMine ? CGPointMake(is, h) :          CGPointMake(0, h),
        self.isMine ? CGPointMake(0, h-is) :        CGPointMake(inset, h-is),
        self.isMine ? CGPointMake(0, is) :          CGPointMake(inset, is),
        self.isMine ? CGPointMake(is, 0) :          CGPointMake(inset+is,0),
    };
    const CGPoint anchor[] = {
        self.isMine ? CGPointMake(0, 0) :           CGPointMake(inset, 0),
        self.isMine ? CGPointMake(w-inset, 0) :     CGPointMake(w, 0),
        self.isMine ? CGPointMake(w-inset, h) :     CGPointMake(w, h),
        self.isMine ? CGPointMake(0, h) :           CGPointMake(inset, h),
        self.isMine ? CGPointMake(0, 0) :           CGPointMake(inset, 0),
    };
    
    for (int i=0; i<sizeof(points)/sizeof(CGPoint); i=i+2) {
        if (i==0) {
            [hexagonPath moveToPoint:CGPointMake(points[i].x, points[i].y)];
        } else {
            [hexagonPath addLineToPoint:CGPointMake(points[i].x, points[i].y)];
        }
        [hexagonPath addQuadCurveToPoint:CGPointMake(points[i+1].x, points[i+1].y) controlPoint:CGPointMake(anchor[i/2].x, anchor[i/2].y)];
    }
    
    hexagonMask.path = hexagonPath.CGPath;
    self.layer.mask = hexagonMask;
}

@end
