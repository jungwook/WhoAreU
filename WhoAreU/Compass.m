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
@property (nonatomic, strong) UIView* pane;
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
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.transform = CGAffineTransformMakeRotation(self.heading * M_PI/180);
}

- (void)drawRect:(CGRect)rect
{
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat h = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2.0f * 0.5f;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArrowFromPoint:CGPointMake(midX, midY+h) toPoint:CGPointMake(midX, midY-h) tailWidth:2 headWidth:6 headLength:6];
    
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
    self.backgroundColor = paneColor;
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = lineColor;
    [self setNeedsDisplay];
}

@end
