//
//  Compass.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 19..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Compass.h"

@interface UIBezierPath (dqd_arrowhead)

+ (UIBezierPath *)bezierPathWithArrowFromPoint:(CGPoint)startPoint
                                           toPoint:(CGPoint)endPoint
                                         tailWidth:(CGFloat)tailWidth
                                         headWidth:(CGFloat)headWidth
                                        headLength:(CGFloat)headLength;

@end

#define kArrowPointCount 7

@implementation UIBezierPath (dqd_arrowhead)

+ (UIBezierPath *)bezierPathWithArrowFromPoint:(CGPoint)startPoint
                                           toPoint:(CGPoint)endPoint
                                         tailWidth:(CGFloat)tailWidth
                                         headWidth:(CGFloat)headWidth
                                        headLength:(CGFloat)headLength {
    CGFloat length = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    
    CGPoint points[kArrowPointCount];
    [self dqd_getAxisAlignedArrowPoints:points
                              forLength:length
                              tailWidth:tailWidth
                              headWidth:headWidth
                             headLength:headLength];
    
    CGAffineTransform transform = [self dqd_transformForStartPoint:startPoint
                                                          endPoint:endPoint
                                                            length:length];
    
    CGMutablePathRef cgPath = CGPathCreateMutable();
    CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
    CGPathCloseSubpath(cgPath);
    
    UIBezierPath *uiPath = [UIBezierPath bezierPathWithCGPath:cgPath];
    CGPathRelease(cgPath);
    return uiPath;
}

+ (void)dqd_getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points
                            forLength:(CGFloat)length
                            tailWidth:(CGFloat)tailWidth
                            headWidth:(CGFloat)headWidth
                           headLength:(CGFloat)headLength {
    CGFloat tailLength = length - headLength;
    points[0] = CGPointMake(0, tailWidth / 2);
    points[1] = CGPointMake(tailLength, tailWidth / 2);
    points[2] = CGPointMake(tailLength, headWidth / 2);
    points[3] = CGPointMake(length, 0);
    points[4] = CGPointMake(tailLength, -headWidth / 2);
    points[5] = CGPointMake(tailLength, -tailWidth / 2);
    points[6] = CGPointMake(0, -tailWidth / 2);
}

+ (CGAffineTransform)dqd_transformForStartPoint:(CGPoint)startPoint
                                       endPoint:(CGPoint)endPoint
                                         length:(CGFloat)length {
    CGFloat cosine = (endPoint.x - startPoint.x) / length;
    CGFloat sine = (endPoint.y - startPoint.y) / length;
    return (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
}

@end

@interface Compass()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) BOOL hasHeading;
@end

@implementation Compass

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
*/

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.lineColor = [UIColor blackColor];
        self.lineWidth = 1.0f;
        self.backgroundColor = [UIColor clearColor];
        self.hasHeading = ([Engine new].simulatorStatus == kSimulatorStatusDevice);

        // displaylink for smooth animation.
        if (self.hasHeading) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay)];
            [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }
    }
    return self;
}

- (void)updateDisplay
{
    static NSUInteger count = 0;
    const int steps = 5;
    
    if (!self.hasHeading || (++count)%steps != 0) {
        return;
    }

    CLLocationDirection trueHeading = [Engine heading];
    CLLocationDirection h = self.heading - trueHeading;
    self.transform = CGAffineTransformMakeRotation(h * M_PI/180);
}

-(void)dealloc
{
    __LF
    if (self.hasHeading) {
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink = nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat h = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2.0f * 0.7f;
    
    CGFloat f = 1.5f, f1=1.0f, f2=0.8;
    UIBezierPath *path = [UIBezierPath bezierPathWithArrowFromPoint:CGPointMake(midX, midY+h) toPoint:CGPointMake(midX, midY-h) tailWidth:h/(1.5*f) headWidth:h/f2 headLength:h/f1];
    
    path.lineWidth = self.lineWidth;
    [self.lineColor setStroke];
    [self.lineColor setFill];
    [path fill];
    [path stroke];
}

- (void)setHeading:(CGFloat)heading
{
    _heading = heading;
    [self setNeedsLayout];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setPaneColor:(UIColor *)paneColor
{
    UIColor *color = [UIColor grayColor];
    self.backgroundColor = self.hasHeading ? paneColor : [color colorWithAlphaComponent:0.2];
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = self.hasHeading ? lineColor : [lineColor colorWithAlphaComponent:0.4];
    [self setNeedsDisplay];
}

@end
