//
//  LocationAnnotationView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LocationAnnotationView.h"

@interface LocationAnnotationView()
@end

@implementation LocationAnnotationView

+ (id)identifier
{
    return @"locationAnnotationView";
}

+ (instancetype)viewWithAnnotation:(LocationAnnotation<MKAnnotation> *)annotation
{
    return [[LocationAnnotationView alloc] initWithAnnotation:annotation];
}

- (void)setHighlighted:(BOOL)highlighted
{
    CGFloat scale = highlighted ? 1.0 : 0.7f;
    super.highlighted = highlighted;
    self.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    [UIView animateWithDuration:0.35
                          delay:0.f
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:
     ^{
         self.transform = CGAffineTransformMakeScale(scale, scale);
         self.layer.zPosition = highlighted ? 100 : 0;
         
         [self setNeedsDisplay];
    } completion:^(BOOL finished) {
    }];
}

- (id)initWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:LocationAnnotationView.identifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.textInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        self.user = annotation.user;
        self.tintColor = self.user.genderColor;
        
        self.highlighted = NO;
        self.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        
        CGRect bounds = [self.user.nickname boundingRectWithFont:self.font maxWidth:FLT_MAX];
        bounds.size.width += self.textInsets.left+self.textInsets.right;
        bounds.size.height += self.textInsets.top+self.textInsets.bottom;
        
        CGFloat w = CGRectGetWidth(bounds), h = CGRectGetHeight(bounds);
        CGFloat leg = h * 0.4f;
        
        self.frame = CGRectMake(-w/2.f, -h/2.f, w, h+leg);
        self.centerOffset = CGPointMake(0, -(h+leg)/2.f);
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    NSString *title = self.user.nickname;
    
    UIColor *color = self.highlighted ? self.tintColor : [self.tintColor colorWithAlphaComponent:0.4];

    CGRect bounds = [self.user.nickname boundingRectWithFont:self.font maxWidth:FLT_MAX];
    bounds.size.width += self.textInsets.left+self.textInsets.right;
    bounds.size.height += self.textInsets.top+self.textInsets.bottom;
    
    CGFloat w = CGRectGetWidth(bounds), h = CGRectGetHeight(bounds);
    CGFloat leg = h * 0.4f;

    UIBezierPath *triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:CGPointMake(w/2.f, h)];
    [triangle addLineToPoint:CGPointMake(w/2.f+leg*0.6f, h+leg)];
    [triangle addLineToPoint:CGPointMake(w/2.f-leg*0.6f, h+leg)];
    [triangle addLineToPoint:CGPointMake(w/2.f, h)];
    triangle.lineJoinStyle = kCGLineJoinRound;
    
    [[color colorWithAlphaComponent:0.4] setFill];
    [triangle fill];

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:4.f];
    [color setFill];
    [path fill];

    id attr = @{
                NSForegroundColorAttributeName : [UIColor whiteColor],
                NSFontAttributeName : self.font,
                };
    [title drawAtPoint:CGPointMake(self.textInsets.left, self.textInsets.top) withAttributes:attr];
}
@end

@implementation LocationAnnotation

+ (instancetype)annotationWithUser:(User *)user
{
    LocationAnnotation *anno = [[LocationAnnotation alloc] initWithLocation:Coords2DFromPoint(user.where)];
    anno.user = user;
    
    return anno;
}

- (id)initWithLocation:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
}
@end

