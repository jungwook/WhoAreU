//
//  DropDownNavigationItem.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 27..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "DropDownNavigationItem.h"
#import "PopupMenu.h"

@interface TriangleView : UIView
@property (strong, nonatomic) UIColor *color;
@end

@implementation TriangleView

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSString *triangle = @"\u25bc";
    
    UIFont *font = [UIFont boldSystemFontOfSize:12];
    
    CGRect box = [triangle boundingRectWithFont:font maxWidth:20];
    CGFloat bw = CGRectGetWidth(box), bh = CGRectGetHeight(box);
    CGFloat w = CGRectGetWidth(rect), h = CGRectGetHeight(rect);

    id attr = @{
                NSFontAttributeName : font,
                NSForegroundColorAttributeName : self.color,
                };
    [triangle drawInRect:CGRectInset(rect, (w-bw)/2.0f, (h-bh)/2.0f) withAttributes:attr];
}

@end

@interface DropDownNavigationItem()
{
    CGFloat iconSize, width;
}
@property (nonatomic, strong) UIView* itemView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) TriangleView *arrowView;
@end

@implementation DropDownNavigationItem

+ (instancetype)new
{
    return [[DropDownNavigationItem alloc] init];
}

+ (instancetype) newWithTitle:(NSString*)title
{
    return [[DropDownNavigationItem alloc] initWithTitle:title];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super initWithTitle:title];
    if (self) {
        [self setup];
        self.titleLabel.text = title;
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    
    CGFloat w = CGRectGetWidth(self.titleLabel.bounds);
    CGFloat ew = MIN(w + iconSize, width);
    CGFloat offset = (width-ew)/2.0f;
    
    self.titleLabel.frame = CGRectMake(offset, 0, w, iconSize);
    self.arrowView.frame = CGRectMake(offset+w, 0, iconSize, iconSize);
}

- (void) tapped:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    BOOL array = [self.menuItems isKindOfClass:[NSArray class]];
    BOOL dic = [self.menuItems isKindOfClass:[NSDictionary class]];
    
    id menu = dic ? @[self.menuItems] : ( array ? self.menuItems : @[] );
    [PopupMenu showFromView:view menuItems:menu completion:self.action cancel:nil];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.titleLabel.textColor = self.textColor;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    self.titleLabel.font = self.font;
}

- (void)setPointerColor:(UIColor *)pointerColor
{
    _pointerColor = pointerColor;
    self.arrowView.color = self.pointerColor;
}

- (void) setup
{
    iconSize = 20.0f;
    width = 200.0f;
    
    self.itemView = [UIView new];
    self.itemView.frame = CGRectMake(0, 0, width, iconSize);
    
    [self.itemView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];

    self.titleLabel = [UILabel new];
    self.arrowView = [TriangleView new];
    self.arrowView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel.frame = self.itemView.bounds;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;

    self.textColor = [UIColor whiteColor];
    self.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.pointerColor = [UIColor colorWithWhite:0.90f alpha:1.0f];
    
    [self.itemView addSubview:self.titleLabel];
    [self.itemView addSubview:self.arrowView];

    self.titleView = self.itemView;
}

@end
