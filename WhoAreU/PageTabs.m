//
//  PageTabs.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PageTabs.h"
#import "BlurView.h"

@interface PageTabItemView : UIView
@property (nonatomic, strong) NSDictionary* item;
@property (nonatomic, strong) UIImageView* iconView;
@property (nonatomic, strong) UILabel* label;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, strong) NSAttributedString *attributedTitle;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic) CGFloat inset, imageSize;
@property (nonatomic, copy) IndexBlock tappedAction;
@property (nonatomic, strong) UIColor *selectedColor, *defaultColor;
@property (nonatomic) BOOL selected;
@end

@implementation PageTabItemView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inset = 4.0f;
        self.imageSize = 20.f;
        
        self.iconView = [UIImageView new];
        self.iconView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.iconView];
        
        self.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        self.label = [UILabel new];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor blackColor];
        self.label.font = self.font;
        self.label.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.label];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedItem:)]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [UIView animateWithDuration:0.15 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.label.textColor = selected ? self.selectedColor : self.defaultColor;
        self.iconView.tintColor = selected ? self.selectedColor : self.defaultColor;
    } completion:nil];
}

- (void)tappedItem:(id)sender
{
    if (self.tappedAction) {
        self.tappedAction(self.tag);
    }
}

- (void)setItem:(NSDictionary *)item
{
    _item = item;
    
    self.title = item[fTitle];
    self.attributedTitle = item[fAttributedTitle];
    self.icon = item[fIcon] ? [UIImage imageNamed:item[fIcon]] : nil;
    self.icon = [self.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    if (title == nil)
        return;
    self.label.text = title;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = attributedTitle;

    if (attributedTitle == nil)
        return;
    self.label.attributedText = attributedTitle;
}

- (void)setIcon:(UIImage *)icon
{
    _icon = icon;
    if (icon==nil)
        return;
    
    self.iconView.image = icon;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds), tH = self.title ? [self.title heightWithFont:self.font maxWidth:w] : (self.attributedTitle ? [self.attributedTitle heightWithMaxWidth:w] : 18), iS = self.imageSize;
    
    self.iconView.frame = CGRectMake((w-iS)/2.0f, self.inset, iS, iS);
    self.label.frame = CGRectMake(0, self.icon ? h-tH : (h-tH)/2.0f, w, tH);
}

@end

@interface PageTabs()
@property (nonatomic, strong) NSMutableArray<PageTabItemView*>* tabItems;
@property (nonatomic, strong) UIView *indicator;
@property (nonatomic) CGFloat inset, indicatorHeight;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) BlurView *blur;
@property (nonatomic, strong) UIView *topLine;
@end

@implementation PageTabs

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.tabItems = [NSMutableArray new];
    self.inset = 4.0f;
    self.indicator = [UIView new];
    self.indicatorHeight = 3.0f;
    self.indicator.radius = self.indicatorHeight/2.0f;
    self.indicator.clipsToBounds = YES;
    self.indicator.backgroundColor = [UIColor redColor];
    self.backgroundColor = [UIColor clearColor];
    
    self.blur = [BlurView viewWithStyle:UIBlurEffectStyleDark];
    [self addSubview:self.blur];

    self.topLine = [UIView new];
    self.topLine.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self addSubview:self.topLine];
}

- (void)setItems:(NSArray<NSDictionary *> *)items
{
    _items = items;
    
    [self clearTabItems];
    [self.items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        PageTabItemView *tabItem = [PageTabItemView new];
        tabItem.item = item;
        tabItem.tag = idx;
        tabItem.tappedAction = ^(NSUInteger index) {
            self.index = index;
        };
        [self.tabItems addObject:tabItem];
        [self addSubview:tabItem];
    }];

    [self.indicator removeFromSuperview];
    [self addSubview:self.indicator];
    [self setNeedsLayout];
    [self.tabItems enumerateObjectsUsingBlock:^(PageTabItemView * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        tabItem.selectedColor = self.selectedColor ? self.selectedColor : [UIColor darkGrayColor];
        tabItem.defaultColor = self.defaultColor ? self.defaultColor : [UIColor lightGrayColor];
        tabItem.selected = (idx == self.index);
    }];
}

- (void) clearTabItems
{
    [self.tabItems enumerateObjectsUsingBlock:^(PageTabItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.tabItems removeAllObjects];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSUInteger count = self.tabItems.count;
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds), itemWidth = w / count;
    
    [self.tabItems enumerateObjectsUsingBlock:^(PageTabItemView * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        tabItem.frame = CGRectInset(CGRectMake(idx*itemWidth, 0, itemWidth, h), self.inset, self.inset);
    }];
    
    self.indicator.frame = CGRectMake(self.index*itemWidth, 0, itemWidth, self.indicatorHeight);
    self.blur.frame = CGRectMake(0, self.indicatorHeight/2.0f, w, h-self.indicatorHeight/2.0f);
    self.topLine.frame = CGRectMake( 0, self.indicatorHeight/2.0f-1.0f, w, 1.0f);
}

- (void)setIndex:(NSUInteger)index
{
    [self.tabItems enumerateObjectsUsingBlock:^(PageTabItemView * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        tabItem.selected = (idx == index);
    }];

    _index = index;

    if (self.selectAction) {
        self.selectAction(index);
    }

    NSUInteger count = self.tabItems.count;
    CGFloat w = CGRectGetWidth(self.bounds), itemWidth = w / count;
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.indicator.frame = CGRectMake(self.index*itemWidth, 0, itemWidth, self.indicatorHeight);
    } completion:nil];
}

@end
