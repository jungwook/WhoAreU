//
//  LocationAnnotationView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LocationAnnotationView.h"

@interface LocationAnnotationView()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *photoView, *paneView, *shadowView;
@property (nonatomic, readonly) UIFont *font;
@property (nonatomic, readonly) UIColor *tintColor, *textColor;
@property (nonatomic, readonly) UIEdgeInsets textInset;
@property (nonatomic, readonly) CGFloat inset, width, height;
@property (nonatomic, readonly) CGRect frameFrame;
@end

@implementation LocationAnnotationView

+ (id)identifier
{
    return @"LocationAnnotationView";
}

- (UIFont *)font
{
    BOOL highlighted = self.locationAnnotation.highlighted;
    return highlighted ? [UIFont systemFontOfSize:15 weight:UIFontWeightBold] : [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
}

- (UIColor *)tintColor
{
    UIColor *color = self.locationAnnotation.user.genderColor;
    BOOL highlighted = self.locationAnnotation.highlighted;
    return highlighted ? color : [color colorWithAlphaComponent:0.4];
}

- (UIColor *)textColor
{
    UIColor *color = [UIColor blackColor];
    BOOL highlighted = self.locationAnnotation.highlighted;
    return highlighted ? color : [color colorWithAlphaComponent:0.4];
}

- (UIEdgeInsets)textInset
{
    return UIEdgeInsetsMake(6, 4, 6, 4);
}

- (CGFloat)inset
{
    return 4.f;
}

- (CGFloat)width
{
    return CGRectGetWidth(self.frameFrame);
}

- (CGFloat)height
{
    return CGRectGetHeight(self.frameFrame);
}

- (CGRect)frameFrame
{
    CGFloat size = 50;
    return CGRectMake(0, 0, size, size*1.15f);
}

+ (instancetype)viewWithAnnotation:(LocationAnnotation<MKAnnotation> *)annotation
{
    return [[LocationAnnotationView alloc] initWithAnnotation:annotation];
}

- (UIImage *)photo
{
    return self.locationAnnotation.photo;
}

- (id)initWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:LocationAnnotationView.identifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        
        self.titleLabel = [UILabel new];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        
        self.paneView = [UIView new];
        
        self.photoView = [UIView new];
        self.photoView.backgroundColor = [UIColor clearColor];
        self.photoView.clipsToBounds = YES;
        self.photoView.backgroundColor = [UIColor whiteColor];

        [self addSubview:self.titleLabel];
        [self addSubview:self.paneView];
        [self.paneView addSubview:self.photoView];
    }
    return self;
}

- (UIBezierPath*) pinPathWithRect:(CGRect)rect
{
    const CGFloat angle = 0.75f; // in radians
    
    CGFloat m = CGRectGetMidX(rect);
    CGFloat w = CGRectGetWidth(rect);
    CGPoint center = CGPointMake(m, m);
    
    UIBezierPath *pin = [UIBezierPath bezierPathWithArcCenter:center radius:w/2.f startAngle:M_PI_2-angle endAngle:M_PI_2+angle clockwise:NO];
    
    center.y = CGRectGetMaxY(rect);
    
    [pin addLineToPoint:center];
    [pin closePath];
    return pin;
}

- (CAShapeLayer*) pinMaskWithFrame:(CGRect)rect
{
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = [self pinPathWithRect:rect].CGPath;
    return mask;
}

-(void)layoutSubviews
{
    self.frame = self.frameFrame;
    [self setViewFrames];
    [self setViewAttributes];
    [self setViewMasks];
    [self setShadows];
    [self drawTitle];
}

- (void)drawTitle
{
    NSString *title = self.title;
    id attr = @{
                NSFontAttributeName : self.font,
                NSStrokeColorAttributeName : [UIColor whiteColor],
                NSForegroundColorAttributeName : [UIColor blackColor],
                NSStrokeWidthAttributeName : @(-4.0),
                };
    
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:attr];
}

- (void)setViewFrames
{
    CGFloat w = [self.titleLabel.text widthWithFont:self.font]+self.inset*2;
    self.titleLabel.frame = CGRectMake((self.width-w)/2.f, self.height, w, 24);
    self.paneView.frame = self.frameFrame;
    self.photoView.frame = self.paneView.bounds;
    
    self.centerOffset = CGPointMake(0, -self.height/2.0f);
    self.layer.zPosition = self.locationAnnotation.highlighted ? 100 : 0;
}

- (void)setShadows
{
    CGFloat shadowWidth = self.width*0.7f, shadowHeight = self.width/4.f;
    self.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.15*shadowWidth, self.height - shadowHeight/2.f, shadowWidth, shadowHeight)].CGPath;
    self.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 0.7f;
    self.layer.shadowRadius = 5.0f;

//    self.titleLabel.shadowRadius = 2.f;
//    self.titleLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    //    self.titleLabel.shadowOffset = CGSizeZero;
}

- (void)setViewAttributes
{
    __drawImage(self.photo, self.photoView);
    self.paneView.backgroundColor = self.tintColor;
    self.photoView.clipsToBounds = YES;
    self.titleLabel.font = self.font;
    self.titleLabel.textColor = self.textColor;
    self.titleLabel.textColor = [UIColor whiteColor];
    [self drawTitle];
}

- (void)setViewMasks
{
    const CGFloat indent = 3.0f;
    self.paneView.layer.mask = [self pinMaskWithFrame:self.frameFrame];
    self.photoView.layer.mask = [self pinMaskWithFrame:CGRectInset(self.frameFrame, indent, indent)];
    self.photoView.clipsToBounds = YES;
}

- (void)setAnnotation:(id<MKAnnotation>)annotation
{
    super.annotation = annotation;
    
    self.titleLabel.text = self.locationAnnotation.user.nickname;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (NSString*)title
{
    return self.annotation.title;
}

- (LocationAnnotation *)locationAnnotation
{
    return (id)self.annotation;
}

@end

@implementation LocationAnnotation

+ (instancetype)annotationWithMap:(MKMapView*)map andUser:(User *)user
{
    LocationAnnotation *anno = [[LocationAnnotation alloc] initWithLocation:Coords2DFromPoint(user.where)];
    anno.user = user;
    anno.parent = map;
    return anno;
}

- (id)initWithLocation:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
    }
    return self;
}

- (LocationAnnotationView *)view
{
    return (id)[self.parent viewForAnnotation:self];
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
}

- (void)setUser:(User *)user
{
    _user = user;
    
    [S3File getImageFromFile:user.thumbnail imageBlock:^(UIImage *image) {
        self.photo = image ?: [UIImage avatar];
        [self.view setNeedsDisplay];
    }];
}

- (NSString *)title
{
    return self.user.nickname;
}

- (void)setHighlighted:(BOOL)highlighted
{
    CGFloat scale = highlighted ? 1.2f : 1.0f;
    
    _highlighted = highlighted;
    
    CATransform3D transform = CATransform3DIdentity;
    
    self.view.layer.transform = transform;
    transform.m34 = 1/500;
    transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
    transform = CATransform3DScale(transform, scale, scale, 1);
    
    [UIView animateWithDuration:0.35f
                          delay:0.f
         usingSpringWithDamping:0.3f
          initialSpringVelocity:0.5f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:
     ^{
         self.view.paneView.layer.transform = transform;
         self.view.layer.zPosition = highlighted ? 100 : 0;
         [self.view drawTitle];
     } completion:^(BOOL finished) {
     }];
}

@end

