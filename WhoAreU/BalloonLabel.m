//
//  BalloonLabel.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "BalloonLabel.h"

#define MEDIASIZE 160

@interface BalloonLabel ()
@property (nonatomic) UIEdgeInsets textInsets;
@property (nonatomic, strong) UIImage *image;
@end

@implementation BalloonLabel

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void) setupVariables
{
    self.mediaWidth = MEDIASIZE;
    self.pointerInset = 8;
    self.cornerRadius = 8;
    self.verticalSpacing = 5;
    self.horizontalSpacing = 8;
    self.type = kBalloonTypeLeft;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setType:(BalloonType)type
{
    _type = type;
    switch (type) {
        case kBalloonTypeRight:
            self.textInsets = UIEdgeInsetsMake(self.verticalSpacing,
                                               self.horizontalSpacing,
                                               self.verticalSpacing,
                                               self.pointerInset+self.horizontalSpacing);
            break;
            
        default:
            self.textInsets = UIEdgeInsetsMake(self.verticalSpacing,
                                               self.pointerInset+self.horizontalSpacing,
                                               self.verticalSpacing,
                                               self.horizontalSpacing);
            break;
    }
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void) setMediaFile:(id)mediaFile
{
    if (mediaFile) {
        [S3File getImageFromFile:mediaFile imageBlock:^(UIImage *image) {
            self.image = image;
            [self setNeedsLayout];
            [self setNeedsDisplay];
        }];
    }
    else {
        self.image = nil;
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if (self.image) {
        UIEdgeInsets insets = self.textInsets;

        CGSize size = self.image.size;
        CGRect rect = CGRectMake(0, 0, self.mediaWidth, size.width > 0 ? self.mediaWidth*size.height/size.width : self.mediaWidth);
        
        rect.origin.x    -= insets.left;
        rect.origin.y    -= insets.top;
        rect.size.width  += (insets.left + insets.right);
        rect.size.height += (insets.top + insets.bottom);
        
        return rect;
    }
    else {
        if (self.text && self.text.length > 0) {
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
        else {
            return CGRectZero;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setShape];
}

- (void)drawTextInRect:(CGRect)rect
{
    if (self.image) {
        [self.image drawInRect:rect];
    }
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
    const CGFloat cr = self.cornerRadius, inset = self.pointerInset;
    
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
