//
//  Balloon.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 31..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Balloon.h"
#import "PhotoView.h"

@interface Balloon()
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) PhotoView *mediaView;
@end

@implementation Balloon

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup
{
    self.leftColor = [UIColor colorWithRed:110/255.f green:200/255.f blue:41/255.f alpha:1];
    self.rightColor = kAppColor;
    
    self.cornerRadius = 8.0f;
    self.ballonInset = 8.0f;
    self.label = [UILabel new];
    self.label.numberOfLines = FLT_MAX;
    self.label.font = chatFont;
    self.label.textColor = [UIColor whiteColor];
    
    self.mediaView = [PhotoView new];
    
    [self addSubview:self.label];
    [self addSubview:self.mediaView];
}

- (void)setMessage:(MessageDic *)message
{
    _message = message;
    
    switch (self.message.messageType) {
        case kMessageTypeMedia:
            self.mediaView.mediaDic = message.media;
            self.label.alpha = 0.0f;
            self.mediaView.alpha = 1.0f;
            break;
            
        case kMessageTypeText:
            self.label.text = message.message;
            self.label.alpha = 1.0f;
            self.mediaView.alpha = 0.0f;
            break;
            
        default:
            break;
    }
    [self setNeedsLayout];
}

- (void)setParent:(UIViewController *)parent
{
    _parent = parent;
    self.mediaView.parent = parent;
}

- (void)setType:(BalloonType)type
{
    _type = type;
    
    switch (self.type) {
        case kBalloonTypeLeft:
            self.backgroundColor = self.leftColor;
            break;
            
        default:
            self.backgroundColor = self.rightColor;
            break;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    switch (self.message.messageType) {
        case kMessageTypeText: {
            CGFloat inset = self.ballonInset;
            CGFloat w = CGRectGetWidth(self.bounds);
            CGFloat h = CGRectGetHeight(self.bounds);
            
            CGFloat o = self.type == kBalloonTypeRight ? INSET : INSET+inset;
            self.label.frame = CGRectMake(o, 0, w-o, h);
        }
            break;
            
        case kMessageTypeMedia: {
            self.mediaView.frame = self.bounds;
        }
            break;
            
        default:
            break;
    }
    [self setShape];
}

//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//    
//    UIBezierPath *path = [self ballonPath];
//    [[UIColor blackColor] setStroke];
//    [path setLineWidth:1.0f];
//    [path stroke];
//}

- (void)setShape
{
    CAShapeLayer *mask = [CAShapeLayer layer];

    mask.path = [self ballonPath].CGPath;
    self.layer.mask = mask;
}

- (UIBezierPath*) ballonPath
{
    const CGFloat cr = self.cornerRadius, inset = self.ballonInset;
    
    CGRect rect = self.frame;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = rect.size.width, h=rect.size.height;
    
    CGFloat s=h-5.0f;
    CGFloat p=h-4.0f;
    CGFloat e=h-12.0f;
    CGFloat f = 0.4f;
    CGFloat m = MAX(h-cr, s);
    
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
