//
//  Segment.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Segment.h"

@interface Segment()
@property (nonatomic, strong) NSMutableArray <UILabel*> *maskingLabels;
@property (nonatomic, strong) NSMutableArray <UILabel*> *labels;
@property (nonatomic, strong) UIView *maskingSlider, *labelGroup, *slider;
@property (nonatomic) CGFloat inset, lineSpacing;
@end

@implementation Segment

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void) initialize
{
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedLabel:)]];
    
    self.inset = 4.0f;
    self.lineSpacing = 4.0f;
    self.labelGroup = [UIView new];
    self.slider = [UIView new];
    self.maskingSlider = [UIView new];
    
//    self.backgroundColor = [UIColor maleColor];
    self.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.maskingLabels = [NSMutableArray new];
    self.labels = [NSMutableArray new];
//    self.faceColor = [UIColor whiteColor];
    self.box = 2;
    
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSlider:)]];

    self.items = @[@"hello", @"world", @"Good", @"better" ];
    [self equalizeWidth];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self setNeedsLayout];
}

-(void)setBox:(CGFloat)box
{
    _box = box;
    [self setNeedsLayout];
}

-(void)setFaceColor:(UIColor *)faceColor
{
    _faceColor = faceColor;
    
    self.maskingSlider.backgroundColor = self.faceColor;
    self.slider.backgroundColor = self.faceColor;
    
    [self setNeedsLayout];
}

- (void)setItems:(NSArray<NSString *> *)items
{
    if (items.count < 1)
        return;
    
    _items = items;
    
    [self setNormalizedWidth];
    [self setupUnderLabels];
    [self setupSliders];
    [self setupLabels];
}

- (void) setupSliders
{
    [self.slider removeFromSuperview];
    [self addSubview:self.slider];
    
    [self.maskingSlider removeFromSuperview];
    [self addSubview:self.maskingSlider];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    if (self.items.count > 0) {
        self.items = self.items;
        self.widths = self.widths;
    }
}

- (void)setupLabels
{
    [self.maskingLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.maskingLabels removeAllObjects];

    [self.items enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = self.font;
        label.textColor = self.backgroundColor;
        label.attributedText = [self attributedTitle:item font:self.font color:self.backgroundColor selected:NO];
        label.tag = idx;
        label.numberOfLines = 0;
        [self.maskingLabels addObject:label];
        [self.labelGroup addSubview:label];
    }];

    self.labelGroup.maskView = nil;
    [self.labelGroup removeFromSuperview];
    [self addSubview:self.labelGroup];
    self.labelGroup.maskView = self.maskingSlider;
}

- (void)setupUnderLabels
{
    [self.labels enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.labels removeAllObjects];
    
    [self.items enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = self.font;
        label.textColor = self.faceColor;
        label.attributedText = [self attributedTitle:item font:self.font color:self.faceColor selected:NO];
        label.tag = idx;
        label.numberOfLines = 0;
        [self.labels addObject:label];
        [self addSubview:label];
    }];
}

- (NSParagraphStyle*) paragraphStyle
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    CGFloat minMaxLineHeight = (self.font.pointSize - self.font.ascender + self.font.capHeight) + self.lineSpacing;
    [style setMinimumLineHeight:minMaxLineHeight];
    [style setMaximumLineHeight:minMaxLineHeight];
    [style setAlignment:NSTextAlignmentCenter];
    
    return style;
}

- (NSAttributedString*) attributedTitle:(NSString*)title
                                   font:(UIFont*)font
                                  color:(UIColor*)color
                               selected:(BOOL)selected
{
    id attr = @{
                NSFontAttributeName : font,
                NSForegroundColorAttributeName : color ? color : [UIColor clearColor],
                };
    
    NSRange range = [title rangeOfString:@"\n"];
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:title attributes:attr];
    
    if (range.location != NSNotFound) {
        NSUInteger l = title.length;
        [attString addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(range.location, l-range.location)];
        
        if (selected) {
            [attString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(range.location, l-range.location)];
        }
    }
    else {
        if (selected) {
            [attString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
        }
    }
    return attString;
}


- (void)panSlider:(UIPanGestureRecognizer*)gesture
{
    static BOOL started = NO;
    static CGPoint startPoint;
    static CGRect oldFrame;
    
    CGPoint point = [gesture locationInView:self];
    CGFloat w = CGRectGetWidth(self.bounds);
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            NSUInteger index = [self indexAtPoint:point];
            if (index == self.selectedIndex) {
                started = YES;
                startPoint = point;
                oldFrame = self.maskingSlider.frame;
            }
            else {
                started = NO;
            }
        }
            break;

        case UIGestureRecognizerStateChanged: {
            if (started && [self point:point inBounds:self.bounds]) {
                CGFloat dx = point.x - startPoint.x;
                
                CGRect frame = oldFrame;
                frame.origin.x += dx;
                
                frame.origin.x = MAX(self.box, frame.origin.x);
                frame.origin.x = MIN(frame.origin.x, w-CGRectGetWidth(self.slider.bounds)-self.box);
                
                self.maskingSlider.frame = frame;
                self.slider.frame = frame;
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            started = NO;
            NSUInteger index = [self indexAtPoint:point];
            self.selectedIndex = index;
        }
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        default: {
            started = NO;
            self.selectedIndex = self.selectedIndex;
        }
            break;
    }
}

- (BOOL) point:(CGPoint)point inBounds:(CGRect)bounds
{
    CGFloat x = point.x;
    return (x >= CGRectGetMinX(bounds) && x<=(CGRectGetMaxX(bounds)+self.inset));
}

- (void) tappedLabel:(UITapGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:self];
    NSUInteger index = [self indexAtPoint:point];
    self.selectedIndex = index;
}

- (NSUInteger) indexAtPoint:(CGPoint)point
{
    __block NSUInteger index = 0;
    
    if (point.x >= floor(CGRectGetWidth(self.bounds))) {
        return self.items.count-1;
    }
    else if (point.x < 0) {
        return index;
    }
    else {
        [self.labels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL contains = [self point:point inBounds:label.frame];
            if (contains) {
                index = idx;
            }
        }];
        return index;
    }
}

- (void) setSelectedIndex:(NSUInteger)selectedIndex
{
    [self sliderToIndex:selectedIndex];
}

- (void) sliderToIndex:(NSUInteger)idx
{
    CGRect frame = [self sliderFrameAtIndex:idx];
    [UIView animateWithDuration:0.25 delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.maskingSlider.frame = frame;
        self.slider.frame = frame;
    } completion:^(BOOL finished) {
        if (finished && self.select && self.selectedIndex != idx) {
            self.select(idx);
        }
        _selectedIndex = idx;
    }];
}

- (void) normalizedWidth
{
    [self setNormalizedWidth];
}

- (void) equalizeWidth
{
    if (self.items.count == 0)
        return;
    NSMutableArray <NSNumber*> *widths = [NSMutableArray new];
    [self.items enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [widths addObject:@(1.0f/(CGFloat)self.items.count)];
    }];
    _widths = widths;
}

- (void) setNormalizedWidth
{
    if (self.items.count == 0)
        return;
    
    NSMutableArray <NSNumber*> *widths = [NSMutableArray new];
    CGFloat width = 0;
    for (NSString* item in self.items) {
        CGFloat w = [item widthWithFont:self.font];
        width += w;
        [widths addObject:@(w)];
    }
    [widths enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        widths[idx] = @([obj floatValue] / width);
    }];
    _widths = widths;
}

- (void) setWidths:(NSArray<NSNumber *> *)widths
{
    __block CGFloat width = 0.0f;
    
    [widths enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        width += obj.floatValue;
    }];
    
    NSMutableArray <NSNumber*> *newWidths = [NSMutableArray new];
    for (NSNumber *w in widths) {
        [newWidths addObject:@(w.floatValue / width)];
    }
    _widths = newWidths;

    [self setNeedsLayout];
}

- (void) layoutSubviews
{
    self.labelGroup.frame = self.bounds;
    
    CGRect innerFrame = [self sliderFrameAtIndex:self.selectedIndex];
    
    self.maskingSlider.frame = innerFrame;
    self.slider.frame = innerFrame;
    self.maskingSlider.radius = CGRectGetHeight(innerFrame)/2.0f;
    self.slider.radius = CGRectGetHeight(innerFrame)/2.0f;
    
    CGFloat h = CGRectGetHeight(self.bounds);
    self.radius = h / 2.0f;
    self.clipsToBounds = YES;
    
    for (int idx=0; idx<self.items.count; idx++) {
        CGRect frame = [self frameAtIndex:idx];
        self.maskingLabels[idx].frame = frame;
        self.labels[idx].frame = frame;
    }
}

- (CGRect) sliderFrameAtIndex:(NSUInteger)index
{
    CGRect frame = CGRectInset([self frameAtIndex:index], self.box, self.box);
    frame.origin.x -= self.inset;
    frame.size.width += self.inset*2.0f;
    
    return frame;
}

- (CGRect) frameAtIndex:(NSUInteger)index
{
    CGFloat w = CGRectGetWidth(self.bounds)-2*self.inset, h = CGRectGetHeight(self.bounds);
    CGFloat width = self.widths[index].floatValue*w;
    CGFloat x = self.inset+[self offsetToIndex:index]*w;
    
    return CGRectMake(x, 0, width, h);
}

- (CGFloat) offsetToIndex:(NSUInteger)index
{
    __block CGFloat offset = 0;
    [self.widths enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (index > idx) {
            offset += obj.floatValue;
        }
    }];
    
    return offset;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
