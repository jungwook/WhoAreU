//
//  SelectionTab.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "SelectionTab.h"
#import "BlurView.h"

#define kSelectionTabFont [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]
#define kSelectionTabBoldFont [UIFont systemFontOfSize:13 weight:UIFontWeightBold]

typedef enum : NSUInteger {
    SelectedItemStyleLeft,
    SelectedItemStyleMiddle,
    SelectedItemStyleRight,
} SelectedItemStyle;

@interface SelectionItem : UIView <CAAnimationDelegate>
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIColor *liveColor;
@property (nonatomic, strong) UIColor *deadColor;
@property (nonatomic, strong) UIColor *liveTextColor;
@property (nonatomic, strong) UIColor *deadTextColor;
@property (nonatomic) BOOL selected;
@property (nonatomic) SelectedItemStyle style;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIFont *font, *selectedFont;
@property (nonatomic, copy) SelectedIndexBlock tappedAction;
@property (nonatomic) NSUInteger index;
@property (nonatomic, readonly) CGFloat textWidth, lineSpacing;
@property (nonatomic) CGFloat pointerHeight, cornerRadius;
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) NSArray <UIColor*> *colors;
@end

@implementation SelectionItem

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.font = kSelectionTabFont;
        self.selectedFont = kSelectionTabBoldFont;
        self.titleLabel = [UILabel new];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
        
        self.pointerHeight = 2.f;
        self.cornerRadius = 4.f;
        _lineSpacing = 4.0f;
        
        
        self.gradientView = [UIView new];
        
        self.gradient = [CAGradientLayer new];
        self.gradient.startPoint = CGPointMake(0, 0.5);
        self.gradient.endPoint = CGPointMake(1, 0.5);
        
        [self.gradientView.layer addSublayer:self.gradient];
        [self addSubview:self.gradientView];
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (CGFloat)textWidth
{
    return CGRectGetWidth([self.title boundingRectWithFont:self.font maxWidth:FLT_MAX]);
}

- (void) setAttributedTitle:(NSAttributedString*)title
{
    self.titleLabel.attributedText = title;
}

- (void) layoutSubviews
{
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    
    self.titleLabel.frame = CGRectMake(0, 0, w, h-self.pointerHeight);
    [self setShape];
    self.gradientView.frame = self.bounds;
    self.gradient.frame = self.bounds;
}

- (void) tapped:(id)sender
{
    if (self.tappedAction && self.selected == NO) {
        self.tappedAction(self.index);
    }
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    UIColor *textColor = (self.selected) ? self.liveTextColor : self.deadTextColor;
    
    [self setShape];
    
    NSAttributedString *attString = [self attributedTitle:self.title
                                               font:self.selected ? self.selectedFont : self.font color:textColor];
    
    UIColor *from = self.selected ? [self.liveColor.darkerColor colorWithAlphaComponent:0.6] : self.deadColor;
    UIColor *to = self.selected ? self.liveColor : self.deadColor;
    
    self.colors = @[(id)from.CGColor,
                    (id)to.CGColor];

    [self.titleLabel setAttributedText:attString];
    [UIView animateWithDuration:0.25 animations:^{
        self.gradient.colors = self.colors;
    } completion:^(BOOL finished) {
        if (finished) {
            if (self.selected) {
                [self.gradient addAnimation:self.animation forKey:@"colorChange"];
            }
            else {
                [self.gradient removeAllAnimations];
            }
        }
    }];
}

- (CABasicAnimation*) animation
{
    static BOOL first = YES;
    first = !first;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    animation.duration = 2.0f;
    animation.toValue = first ? @[self.colors.lastObject, self.colors.firstObject] : @[self.colors.lastObject, self.colors.firstObject];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = YES;
    animation.delegate = self;
    animation.autoreverses = YES;
    
    return animation;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag) {
        if (self.selected) {
            [self.gradient addAnimation:self.animation forKey:@"colorChange"];
        }
        else {
            [self.gradient removeAllAnimations];
        }
    }
}

- (NSAttributedString*) attributedTitle:(NSString*)title
                                   font:(UIFont*)font
                                  color:(UIColor*)color
{
    id attr = @{
                NSFontAttributeName : font,
                NSForegroundColorAttributeName : color,
                };
    
    NSRange range = [title rangeOfString:@"\n"];
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:title attributes:attr];
    
    if (range.location != NSNotFound) {
        NSUInteger l = title.length;
        [attString addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(range.location, l-range.location)];
        
        if (self.selected) {
            [attString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(range.location, l-range.location)];
        }
    }
    else {
        if (self.selected) {
            [attString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
        }
    }
    return attString;
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

- (void)setShape
{
    CAShapeLayer *mask = [CAShapeLayer layer];
    
    mask.path = [self path].CGPath;
    self.layer.mask = mask;
}

#define PM(__X__,__Y__) CGPointMake(__X__, __Y__)

- (UIBezierPath*) path
{
    const CGFloat cr = self.cornerRadius, inset = self.pointerHeight;
    
    CGRect rect = self.bounds;
    CGFloat w = rect.size.width, H=rect.size.height, h=rect.size.height-inset;
    CGFloat m = CGRectGetMidX(rect);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    switch (self.style) {
        case SelectedItemStyleLeft:
            [path moveToPoint:PM(0, cr)];
            [path addQuadCurveToPoint:PM(cr, 0) controlPoint:PM(0, 0)];
            [path addLineToPoint:PM(w, 0)];
            [path addLineToPoint:PM(w, h)];
            if (self.selected) {
                [path addLineToPoint:PM(m+cr, h)];
                [path addLineToPoint:PM(m, H)];
                [path addLineToPoint:PM(m-cr, h)];
            }
            [path addLineToPoint:PM(cr, h)];
            [path addQuadCurveToPoint:PM(0, h-cr) controlPoint:PM(0, h)];
            [path addLineToPoint:PM(0, cr)];
            break;
            
        case SelectedItemStyleMiddle:
            [path moveToPoint:PM(0, 0)];
            [path addLineToPoint:PM(w,0)];
            [path addLineToPoint:PM(w, h)];
            if (self.selected) {
                [path addLineToPoint:PM(m+cr, h)];
                [path addLineToPoint:PM(m, H)];
                [path addLineToPoint:PM(m-cr, h)];
            }
            [path addLineToPoint:PM(0, h)];
            [path addLineToPoint:PM(0, 0)];
            break;
            
        case SelectedItemStyleRight:
            [path moveToPoint:PM(0, 0)];
            [path addLineToPoint:PM(w-cr,0)];
            [path addQuadCurveToPoint:PM(w, cr) controlPoint:PM(w, 0)];
            [path addLineToPoint:PM(w, h-cr)];
            [path addQuadCurveToPoint:PM(w-cr, h) controlPoint:PM(w, h)];
            if (self.selected) {
                [path addLineToPoint:PM(m+cr, h)];
                [path addLineToPoint:PM(m, H)];
                [path addLineToPoint:PM(m-cr, h)];
            }
            [path addLineToPoint:PM(0, h)];
            [path addLineToPoint:PM(0, 0)];
            break;
    }
    
    return path;
}
@end

@interface SelectionTab()
@property (strong, nonatomic) NSArray <NSString*> *tabs;
@property (strong, nonatomic) NSMutableArray <SelectionItem*> *items;
@property (strong, nonatomic) UIColor *fromColor, *toColor;
@property (nonatomic) CGFloat totalWidth;
@end

@implementation SelectionTab

+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.tabs = tabs;
    tab.selectAction = action;

    return tab;
}

+ (instancetype)newWithTabs:(NSArray<NSString *> *)tabs
                     widths:(NSArray<NSNumber *> *)widths
                     action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.tabs = tabs;
    tab.widths = [NSMutableArray arrayWithArray:widths];
    tab.selectAction = action;

    return tab;
}

+ (instancetype)newWithTabs:(NSArray<NSString *> *)tabs
                     colors:(NSArray<UIColor *> *)colors
                     action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.tabs = tabs;
    tab.liveColors = [NSMutableArray arrayWithArray:colors];
    tab.selectAction = action;

    return tab;
}

+ (instancetype)newWithTabs:(NSArray<NSString *> *)tabs
                     widths:(NSArray<NSNumber *> *)widths
                     colors:(NSArray<UIColor *> *)colors
                     action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.tabs = tabs;
    tab.widths = [NSMutableArray arrayWithArray:widths];
    tab.liveColors = [NSMutableArray arrayWithArray:colors];
    tab.selectAction = action;
    
    return tab;
}

+ (instancetype)newWithTabs:(NSArray<NSString *> *)tabs
                  fromColor:(UIColor *)fromColor
                    toColor:(UIColor *)toColor
                     action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.fromColor = fromColor;
    tab.toColor = toColor;
    tab.tabs = tabs;
    tab.selectAction = action;
    
    return tab;
}

+ (instancetype)newWithTabs:(NSArray<NSString *> *)tabs
                     widths:(NSArray<NSNumber *> *)widths
                  fromColor:(UIColor *)fromColor
                    toColor:(UIColor *)toColor
                     action:(SelectedIndexBlock)action
{
    SelectionTab *tab = [SelectionTab new];
    tab.fromColor = fromColor;
    tab.toColor = toColor;
    tab.tabs = tabs;
    tab.widths = [NSMutableArray arrayWithArray:widths];
    tab.selectAction = action;

    return tab;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray new];
        _widths = [NSMutableArray new];
        self.fromColor = [UIColor redColor];
        self.toColor = [UIColor yellowColor];
    }
    return self;
}

- (void)setWidths:(NSMutableArray<NSNumber *> *)widths
{
    self.totalWidth = 0;
    
    for (NSNumber *w in widths) {
        self.totalWidth += w.floatValue;
        [self.widths addObject:w];
    }
}

- (void)setLiveColors:(NSMutableArray<UIColor *> *)liveColors
{
    [liveColors enumerateObjectsUsingBlock:^(UIColor * _Nonnull liveColor, NSUInteger idx, BOOL * _Nonnull stop) {
        SelectionItem *item = [self.items objectAtIndex:idx];
        item.liveColor = liveColor;
        item.deadColor = liveColor.grayscale;
        item.liveTextColor = [UIColor whiteColor];
        item.deadTextColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    }];
    
    self.fromColor = [liveColors firstObject];
    self.toColor = [liveColors lastObject];
}

- (void)setTotalWidth:(CGFloat)totalWidth
{
    _totalWidth = totalWidth;
    if (totalWidth == 0) {
        [self.widths removeAllObjects];
    }
}

- (void)setTabs:(NSArray *)tabs
{
    _tabs = tabs;
    
    [self.items enumerateObjectsUsingBlock:^(SelectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.items removeAllObjects];
    
    self.totalWidth = 0;

    [tabs enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {

        UIColor *color = [UIColor interpolateRGBColorFrom:self.fromColor
                                                       to:self.toColor
                                             withFraction:((CGFloat)idx)/((CGFloat)tabs.count)];
        
        SelectionItem *item = [SelectionItem new];
        [item setIndex:idx];
        [item setTitle:[title uppercaseString]];
        [item setTappedAction:^(NSUInteger index) {
            self.selectedIndex = index;
            if (self.selectAction) {
                self.selectAction(index);
            }
        }];
        [item setClipsToBounds:YES];
        [item setLiveColor:color];
        [item setDeadColor:color.grayscale];
        [item setLiveTextColor:[UIColor whiteColor]];
        [item setDeadTextColor:[[UIColor whiteColor] colorWithAlphaComponent:0.6]];
        [item setStyle:idx == 0 ? SelectedItemStyleLeft : (idx==tabs.count-1 ? SelectedItemStyleRight : SelectedItemStyleMiddle)];

        [self.items addObject:item];
        [self addSubview:item];

        CGFloat width = item.textWidth;
        self.totalWidth += width;
        [self.widths addObject:@(width)];
    }];
    
    self.selectedIndex = 0;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    
    [self.items enumerateObjectsUsingBlock:^(SelectionItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        item.selected = (idx == selectedIndex);
    }];
}

- (void)layoutSubviews
{
    if (self.items.count == 0)
        return;

    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    
    [self.items enumerateObjectsUsingBlock:^(SelectionItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat width = [self widthForButtonAtIndex:idx]/self.totalWidth;
        CGFloat p = [self widthBeforeButtonAtIndex:idx]/self.totalWidth;
        
        item.frame = CGRectMake(p*w,
                                  0,
                                  width*w,
                                  h);
        
        item.selected = (item.index == self.selectedIndex);
    }];
}

- (CGFloat) widthForButtonAtIndex:(NSUInteger)idx
{
    return [self.widths[idx] floatValue];
}

- (CGFloat) widthBeforeButtonAtIndex:(NSUInteger)idx
{
    CGFloat w = 0;
    for (int i=0; i<idx; i++) {
        w += [self.widths[i] floatValue];
    }
    return w;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
