//
//  Compass.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 19..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Compass.h"

@interface UIBezierPath (arrowhead)

+ (UIBezierPath *)arrowFromPoint:(CGPoint)startPoint
                         toPoint:(CGPoint)endPoint
                       tailWidth:(CGFloat)tailWidth
                       headWidth:(CGFloat)headWidth
                      headLength:(CGFloat)headLength;

@end

#define kArrowPointCount 7

@implementation UIBezierPath (arrowhead)

+ (UIBezierPath *)arrowFromPoint:(CGPoint)startPoint
                         toPoint:(CGPoint)endPoint
                       tailWidth:(CGFloat)tailWidth
                       headWidth:(CGFloat)headWidth
                      headLength:(CGFloat)headLength {
    CGFloat length = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    
    CGPoint points[kArrowPointCount];
    [self getAxisAlignedArrowPoints:points
                          forLength:length
                          tailWidth:tailWidth
                          headWidth:headWidth
                         headLength:headLength];
    
    CGAffineTransform transform = [self transformForStartPoint:startPoint
                                                      endPoint:endPoint
                                                        length:length];
    
    CGMutablePathRef cgPath = CGPathCreateMutable();
    CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
    CGPathCloseSubpath(cgPath);
    
    UIBezierPath *uiPath = [UIBezierPath bezierPathWithCGPath:cgPath];
    CGPathRelease(cgPath);
    return uiPath;
}

+ (void)getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points
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

+ (CGAffineTransform)transformForStartPoint:(CGPoint)startPoint
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
        _lineWidth = 1.0f;
        _lineColor = [UIColor clearColor];
        _northColor = [UIColor blackColor];
        _paneColor = [UIColor redColor];
        self.backgroundColor = [UIColor clearColor];
        
        // displaylink for smooth animation.
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)updateDisplay
{
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

UIColor* realColor(UIColor *col)
{
    BOOL hasHeading = ([Engine new].simulatorStatus == kSimulatorStatusDevice);
    return [col colorWithAlphaComponent:hasHeading ? 1.0 : 0.2];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat w = CGRectGetWidth(rect), h = CGRectGetHeight(rect);
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
//    CGFloat hp = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 2.0f * 0.7f;
    
    UIBezierPath *triangle = [UIBezierPath new];
    
    [triangle moveToPoint:CGPointMake(midX, 0)];
    [triangle addLineToPoint:CGPointMake(midX-midY/3.0f, midY/2.0f)];
    [triangle addLineToPoint:CGPointMake(midX+midY/3.0f, midY/2.0f)];
    [triangle addLineToPoint:CGPointMake(midX, 0)];
    
    triangle.lineWidth = self.lineWidth;

    [realColor(self.lineColor) setStroke];
    [realColor(self.paneColor) setFill];
    [triangle fill];
    [triangle stroke];
    
    NSString *north = @"N";
    UIFont *font = [UIFont systemFontOfSize:floor(h/2.0f) weight:UIFontWeightBlack];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    
    id attr = @{
                NSFontAttributeName : font,
                NSForegroundColorAttributeName : realColor(self.northColor),
                NSParagraphStyleAttributeName : style,
                };
    [north drawInRect:CGRectMake(0, midY/2.0f, w, h*2/3.0f) withAttributes:attr];
    
//    UIBezierPath *path = [UIBezierPath arrowFromPoint:CGPointMake(midX, midY+h) toPoint:CGPointMake(midX, midY-h) tailWidth:h/(1.5*f) headWidth:h/f2 headLength:h/f1];
//    
//    path.lineWidth = self.lineWidth;
//    [self.lineColor setStroke];
//    [self.lineColor setFill];
//    [path fill];
//    [path stroke];
}

- (void)setHeading:(CGFloat)heading
{
    _heading = heading;

    self.hasHeading = ([Engine new].simulatorStatus == kSimulatorStatusDevice);
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setPaneColor:(UIColor *)paneColor
{
    _paneColor = paneColor;
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = lineColor;
    [self setNeedsDisplay];
}

- (void)setNorthColor:(UIColor *)northColor
{
    _northColor = northColor;
    [self setNeedsDisplay];
}

@end
