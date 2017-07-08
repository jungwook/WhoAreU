//
//  TabBar.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "TabBar.h"
#import "BlurView.h"

@class TabBar;

@interface TabBarCell : UICollectionViewCell
@property (weak, nonatomic) TabBar *parent;
@property (strong, nonatomic) NSDictionary *item;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *icon;
@property (strong, nonatomic) UIColor *selectedColor, *deselectedColor;
@property (strong, nonatomic) UIImage *selectedImage, *deselectedImage;
@property (strong, nonatomic) NSString *title;
@property (nonatomic) BOOL showIcon, showTitle;
@end

@implementation TabBarCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
//    self.selectedColor = [UIColor whiteColor];
    
    self.label = [UILabel new];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.badgeFont = [UIFont systemFontOfSize:6];
    self.label.badgeOriginY = 0;
    self.label.badgeOriginX = 0;
    self.label.shouldAnimateBadge = NO;
    self.label.badgeTextColor = [UIColor colorWithWhite:1.f alpha:1.f];
    
    self.icon = [UIImageView new];
    [self.icon setContentMode:UIViewContentModeScaleAspectFit];
    [self.icon setClipsToBounds:YES];
    [self addSubview:self.icon];
    [self addSubview:self.label];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGFloat height = 20.f, inset = 10.f, size = 25.f;
    
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    self.label.frame = self.bounds;
    self.icon.frame = CGRectInset(self.bounds, inset, inset);
    
    if (self.showTitle && self.showIcon) {
        self.label.frame = CGRectMake(0, h-height, w, height);
        self.icon.frame = CGRectMake((w-size)/2.0f, 8.0f, size, size);
    }
    else if (self.showIcon) {
        self.icon.frame = CGRectMake((w-size)/2.0f, (h-size)/2.0f, size, size);
        self.label.frame = CGRectZero;
    }
    else {
        self.label.frame = self.bounds;
        self.icon.frame = CGRectZero;
    }
}

- (void)setSelected:(BOOL)selected
{
    super.selected = selected;
    
    UIColor *color = self.selectedColor ? self.selectedColor : [UIColor whiteColor];
    UIColor *deColor = self.deselectedColor ? self.deselectedColor : [self.selectedColor colorWithAlphaComponent:0.6];
    
    self.deselectedImage = self.deselectedImage ? self.deselectedImage : self.selectedImage;
    self.icon.image = self.selected ? self.selectedImage : self.deselectedImage;

    self.label.font = self.showIcon ? (self.selected ? self.parent.selectedSmallFont : self.parent.smallFont) : (self.selected ? self.parent.selectedFont : self.parent.font);
    
    self.label.textColor = self.selected ? color : deColor;
    self.icon.tintColor = self.selected ? color : deColor;
    
    self.label.badgeBGColor = self.label.textColor;
    
    [self setNeedsLayout];
}

-(void)setItem:(NSDictionary *)item
{
    _item = item;
    
    self.title = [item objectForKey:fTitle];
    self.label.text = [self.title uppercaseString];
    self.label.badgeValue = [[item objectForKey:@"badge"] stringValue];
    self.label.badgeOriginX = [self.title widthWithFont:self.label.badgeFont]+26.f;
    
    self.selectedImage = [[UIImage imageNamed:[item objectForKey:fIcon]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.deselectedImage = [[UIImage imageNamed:[item objectForKey:fDeselectedIcon]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.deselectedImage = self.selectedImage;

    self.icon.image = self.selectedImage;
    
    self.showIcon = (self.selectedImage != nil);
    self.showTitle = (self.title != nil);

    self.label.font = self.showIcon ? (self.selected ? self.parent.selectedSmallFont : self.parent.smallFont) : (self.selected ? self.parent.selectedFont : self.parent.font);
    
    self.label.badgeTextColor = self.parent.backgroundColor;
}

@end


@interface TabBar() <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, readonly) CGFloat defaultWidth, inset, w, h, indicatorInset, indicatorHeight;
@property (nonatomic, readonly) CGRect indicatorFrame;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, strong) UIView* indicator;
@property (nonatomic, strong) UIView* gradientView;
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) BlurView *blurView;
@end

@implementation TabBar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

-(void)setItems:(NSArray<NSDictionary *> *)items
{
    _items = items;
    
    [self.collectionView reloadData];
}

- (UIFont *)font
{
    return self.smallFonts ? self.smallFont : [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
}

- (UIFont *)smallFont
{
    return [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
}

- (UIFont *)selectedFont
{
    return self.smallFonts ? self.selectedSmallFont : [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
}

- (UIFont *)selectedSmallFont
{
    return [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
}

- (void)setupVariables
{
    self.equalWidth = YES;
    [self.blurView removeFromSuperview];
    self.blurView = [BlurView viewWithStyle:UIBlurEffectStyleLight];
    self.blurView.alpha = NO;
    [self addSubview:self.blurView];
    
    [self.gradientView removeFromSuperview];
    self.gradientView = [UIView new];
    
    self.gradient = [CAGradientLayer new];
    [self.gradientView.layer addSublayer:self.gradient];
    [self addSubview:self.gradientView];
    
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(0, self.inset, 0, self.inset);
    layout.minimumLineSpacing = 10.f;
    layout.minimumInteritemSpacing = 10.f;

    [self.collectionView removeFromSuperview];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 200, 100) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    
    [self addSubview:self.collectionView];
    [self.collectionView registerClass:[TabBarCell class] forCellWithReuseIdentifier:@"TabBarCell"];
    
    [self.indicator removeFromSuperview];
    self.indicator = [UIView new];
    self.indicatorColor = [UIColor whiteColor];
    self.selectedColor = [UIColor whiteColor];
    
    [self.collectionView addSubview:self.indicator];
    
    self.position = kTabBarIndicatorPositionBottom;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView reloadData];
}

- (void)setGradientOn:(BOOL)gradientOn
{
    _gradientOn = gradientOn;
    self.gradientView.alpha = gradientOn;
}

- (void)setBlurOn:(BOOL)blurOn
{
    _blurOn = blurOn;
    self.blurView.alpha = blurOn;
}

- (void)setIndicatorColor:(UIColor *)indicatorColor
{
    _indicatorColor = indicatorColor;
    self.indicator.backgroundColor = self.indicatorColor;
    [self.collectionView reloadData];
    [self setNeedsLayout];
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
    [self.collectionView reloadData];
    [self setNeedsLayout];
}

-(void)setDeselectedColor:(UIColor *)deselectedColor
{
    _deselectedColor = deselectedColor;
    [self.collectionView reloadData];
    [self setNeedsLayout];
}

- (void)setPosition:(TabBarIndicatorPosition)position
{
    _position = position;
    self.indicator.alpha = (self.position != kTabBarIndicatorPositionNone);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.blurView.frame = self.bounds;
    self.gradientView.frame = self.bounds;
    self.gradient.frame = self.gradientView.bounds;
    self.collectionView.frame = self.bounds;
    self.indicator.frame = self.indicatorFrame;

    self.gradient.colors = @[
                             (id)[UIColor colorWithWhite:1 alpha:1].CGColor,
                             (id)[UIColor colorWithWhite:1 alpha:0.8].CGColor,
                             (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                             ];
    self.gradient.locations = @[
                                @(0.0),
                                @(0.6),
                                @(1.0),
                                ];
}

- (NSIndexPath *)indexPath
{
    return [NSIndexPath indexPathForRow:self.index inSection:0];
}

- (void)setIndex:(NSUInteger)index
{
    self.indicator.frame = self.indicatorFrame;
    
    _index = index;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.indicator.frame = self.indicatorFrame;
    }];
    [self.collectionView reloadData];
}

- (CGRect)indicatorFrame
{
    const CGFloat offset = 4.0f;
    CGRect frame = [self.collectionView layoutAttributesForItemAtIndexPath:self.indexPath].frame;
    CGFloat xpos = frame.origin.x + self.indicatorInset;
    CGFloat ypos = (self.position == kTabBarIndicatorPositionTop) ? offset : (self.position == kTabBarIndicatorPositionBottom) ? self.h+self.indicatorHeight - offset : 0;
    CGFloat width = frame.size.width - 2*self.indicatorInset;
    return CGRectMake(xpos,
                      ypos,
                      width,
                      self.indicatorHeight);
}

- (CGFloat)w
{
    return CGRectGetWidth(self.bounds);
}

- (CGFloat)h
{
    return CGRectGetHeight(self.bounds);
}

- (CGFloat)indicatorHeight
{
    return 2.0f;
}

- (CGFloat)indicatorInset
{
    return 4.0f;
}

- (CGFloat)defaultWidth
{
    return 200.f;
}

- (CGFloat)inset
{
    return 8.f;
}

- (CGFloat) itemWidth:(NSDictionary*)item
{
    id title = [item objectForKey:fTitle];
    if ([title isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *aString = title;
        return self.inset + [aString width] + self.inset;
    }
    else if ([title isKindOfClass:[NSString class]]) {
        NSString *string = title;
        return self.inset + [string widthWithFont:self.font] + self.inset;
    }
    else {
        return self.defaultWidth;
    }
}

- (void)addItem:(NSDictionary *)item
{
    NSMutableArray *menus = [NSMutableArray arrayWithArray:self.items];
    [menus addObject:item];
    self.items = menus;
    [self.collectionView reloadData];
}

- (void)updateItem:(NSDictionary *)item atIndex:(NSUInteger)index
{
    if (index>=self.items.count || item == nil) {
        return;
    }
    NSMutableArray *menus = [NSMutableArray arrayWithArray:self.items];
    [menus replaceObjectAtIndex:index withObject:item];
    self.items = menus;
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger idx = indexPath.row;
    TabBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TabBarCell" forIndexPath:indexPath];

    cell.selectedColor = self.selectedColor;
    cell.deselectedColor = self.deselectedColor;
    cell.parent = self;
    cell.selected = (idx == self.index);
    cell.item = [self.items objectAtIndex:idx];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger count = self.items.count, sections = collectionView.numberOfSections;
    CGFloat width = CGRectGetWidth(self.bounds), height = CGRectGetHeight(self.bounds);
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) collectionView.collectionViewLayout;
    
    NSUInteger  spacings = MAX(count - sections, 0);
    CGFloat     spacing = layout.minimumLineSpacing;
    CGFloat     horizontal = layout.sectionInset.left + layout.sectionInset.right;
    CGFloat     vertical = layout.sectionInset.top + layout.sectionInset.bottom;
    
    CGFloat w = MAX((width-(horizontal*sections + spacing*spacings))/count, 0);
    CGFloat h = MAX(height-vertical, 0);
    
    if (self.equalWidth) {
        return CGSizeMake(w, h);
    }
    else {
        id item = [self.items objectAtIndex:indexPath.row];
        NSString *title = [item objectForKey:fTitle];
        CGFloat w = [title widthWithFont:self.selectedFont]+4*self.inset;
        return CGSizeMake(w, h);
    }
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.index = indexPath.row;

    if (self.equalWidth == NO) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    
    if (self.selectAction) {
        self.selectAction(self.index);
    }
}

@end
