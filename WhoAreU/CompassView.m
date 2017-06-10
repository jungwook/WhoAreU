//
//  CompassView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "CompassView.h"

@interface CompassView()
@property (strong, nonatomic) CADisplayLink* displayLink;
@property (nonatomic, readonly) CGFloat maskFactor;
@end

@implementation CompassView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.compassColor = [UIColor blackColor];
    self.textColor = [UIColor whiteColor];
    self.pointerColor = [UIColor redColor];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (CGFloat)maskFactor
{
    return [Engine headingAvailable] ? 1.0 : 0.5f;
}

// displaylink for smooth animation.

- (void)updateDisplay
{
    CLLocationDirection h = self.heading - [Engine heading];
    self.transform = CGAffineTransformMakeRotation(degreesToRadians(h));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = [UIColor clearColor];
}

- (void)setHeading:(CGFloat)heading
{
    _heading = heading;
    
    self.transform = CGAffineTransformMakeRotation(degreesToRadians(self.heading));
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (UIColor*) mCompassColor
{
    return [self.compassColor colorWithAlphaComponent:self.maskFactor];
}

- (UIColor*) mTextColor
{
    return [self.textColor colorWithAlphaComponent:self.maskFactor];
}

- (UIColor *)mPointerColor
{
    return [self.pointerColor colorWithAlphaComponent:self.maskFactor];
}

- (void)drawRect:(CGRect)rect
{
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat radius = MIN(CGRectGetWidth(rect)/2.0, CGRectGetHeight(rect)/2.0);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle:2*M_PI clockwise:YES];
    
    [self.mCompassColor setFill];
    [path fill];
    
    for (CGFloat angle = 0; angle<360.0; angle+=360.0/16.0f) {
        CGFloat outFactor = 0.9f, inFactor = 0.7f;
        CGFloat xo = sin(degreesToRadians(angle))*radius*outFactor+center.x,
                yo = cos(degreesToRadians(angle))*radius*outFactor+center.y;
        CGFloat xi = sin(degreesToRadians(angle))*radius*inFactor+center.x,
                yi = cos(degreesToRadians(angle))*radius*inFactor+center.y;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(xi, yi)];
        [path addLineToPoint:CGPointMake(xo, yo)];
        
        [self.mTextColor setStroke];
        [path setLineWidth:1.0f];
        [path stroke];
    }
    
    CGFloat outFactor = 0.6f, inFactor = 0.2f, endFactor = 0.0f;
    UIBezierPath *tri = [UIBezierPath bezierPath];
    [tri moveToPoint:CGPointMake(center.x, -radius*outFactor+center.y)];
    [tri addLineToPoint:CGPointMake(center.x+radius*inFactor, -radius*inFactor+center.y)];
    [tri addLineToPoint:CGPointMake(center.x-radius*inFactor, -radius*inFactor+center.y)];
    [tri addLineToPoint:CGPointMake(center.x, -radius*outFactor+center.y)];
    [self.mPointerColor setFill];
    [tri fill];
    
    NSString *north = @"N";
    UIFont *font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    CGRect bound = [north boundingRectWithFont:font maxWidth:FLT_MAX];
    CGFloat width = CGRectGetWidth(bound);
    
    id attr = @{
                NSFontAttributeName : font,
                NSStrokeColorAttributeName : self.mTextColor,
                NSForegroundColorAttributeName : self.mTextColor,
                };

    [north drawInRect:CGRectMake(center.x-width/2.0f, center.y-radius*(inFactor+endFactor), width, radius*(1.0f-inFactor)) withAttributes:attr];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
*/

@end
