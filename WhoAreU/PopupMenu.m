//
//  PopupMenu.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 26..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PopupMenu.h"


#define identifierMenuCell @"UITableViewCell.MenuCell"
#define identifierCellContent @"UITableViewCellContentView"
#define identifierErrorMessage @"PopupMenu: unknown sender class to start menu."

@interface PopupMenuCell : UITableViewCell
@property (nonatomic, strong) UILabel *menuLabel;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) CGFloat inset, iconSize;
@property (nonatomic) UIView* separatorLine;
@end

@implementation PopupMenuCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.menuLabel = [UILabel new];
        self.icon = [UIImageView new];
        [self addSubview:self.icon];
        [self addSubview:self.menuLabel];
    }
    return self;
}

- (void) setMenuItem:(NSString*)menu
                icon:(UIImage*)image
                font:(UIFont*)font
               inset:(CGFloat)inset
            iconSize:(CGFloat)iconSize
           separator:(BOOL)separator
           textColor:(UIColor*)textColor
       textAlignment:(NSTextAlignment)alignment
      separatorColor:(UIColor*)separatorColor
{
    self.menuLabel.font = font;
    self.menuLabel.text = menu;
    self.menuLabel.textColor = textColor;
    self.menuLabel.numberOfLines = FLT_MAX;
    self.menuLabel.textAlignment = alignment;
    self.inset = inset;
    self.image = image;
    self.iconSize = iconSize;
    if (self.image) {
        [self.icon setTintColor:[UIColor blackColor]];
        [self.icon setImage:image];
    }
    if (separator) {
        self.separatorLine = [UIView new];
        self.separatorLine.backgroundColor = separatorColor;
        [self addSubview:self.separatorLine];
    }
    else {
        self.separatorLine = nil;
    }
}

- (void)layoutSubviews
{
    CGRect rect = self.bounds;
    CGFloat w = CGRectGetWidth(rect), h = CGRectGetHeight(rect);
    if (self.image) {
        self.icon.frame = CGRectMake(self.inset,
                                     (h-self.iconSize)/2.0f,
                                     self.iconSize,
                                     self.iconSize);
        self.menuLabel.frame = CGRectMake(self.inset*2 + self.iconSize,
                                          0,
                                          w-3*self.inset-self.iconSize,
                                          h);
    }
    else {
        self.icon.frame = CGRectZero;
        self.menuLabel.frame = CGRectMake(self.inset,
                                          0,
                                          w-2*self.inset,
                                          h);
    }
    if (self.separatorLine) {
        CGFloat add = self.image ? self.inset + self.iconSize : 0;
        self.separatorLine.frame = CGRectMake(self.inset*1 + add,
                                              0,
                                              w-2*self.inset-add,
                                              0.5);
    }
}

@end

@interface PopupMenu () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, readonly) CGFloat inset, maxWidth, width, height, iconSize, pointerHeight, cornerRadius, headerHeight, footerHeight;
@property (nonatomic) PopupMenuDirection direction, pointerPosition;
@property (nonatomic, strong) BlurView* menuView;
@property (nonatomic, strong) UIView* screenView;
@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, copy) SectionIndexBlock completionHandler;
@property (nonatomic, copy) VoidBlock cancelHandler;
@end

@implementation PopupMenu

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithMenuItems:(NSArray*)menuItems
{
    self = [super init];
    if (self) {
        [self setupVariables];
        self.menuItems = menuItems;
    }
    return self;
}

- (void) setupVariables
{
    self.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.headerFont = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    
    _inset = 8.0f;
    _headerHeight = [@"X" heightWithFont:self.headerFont maxWidth:FLT_MAX] + 1*self.inset;
    _footerHeight = self.inset / 2.0f;
    _maxWidth = 200.0f;
    _iconSize = [@"X" heightWithFont:self.font maxWidth:FLT_MAX];
    _pointerHeight = 5.0f;
    _direction = kPopupMenuDirectionDown;
    _cornerRadius = 8.0f;
    _separatorColor = [UIColor groupTableViewBackgroundColor];
    _textColor = [UIColor darkGrayColor];
    _textAlignment = NSTextAlignmentLeft;

    self.menuView = [BlurView new];
    self.menuView.backgroundColor = [UIColor whiteColor];
    
    self.shadowView = [UIView new];
    self.shadowView.backgroundColor = [UIColor clearColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 10);
    self.tableView.scrollEnabled = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.tableView registerClass:[PopupMenuCell class] forCellReuseIdentifier:identifierMenuCell];
    
    self.menuView.clipsToBounds = YES;
    [self.menuView addSubview:self.tableView];
    
    [self addSubview:self.shadowView];
    [self.shadowView addSubview:self.menuView];
}

- (void)setMenuItems:(NSArray *)menuItems
{
    _menuItems = menuItems;
    
    [self.tableView reloadData];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = self.menuPath.CGPath;
    
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    
    self.shadowView.frame = self.bounds;
    self.menuView.frame = self.bounds;
    self.menuView.layer.mask = mask;
    
    self.tableView.frame = self.direction == kPopupMenuDirectionDown ? CGRectMake(0, self.pointerHeight, w, h-self.pointerHeight) :
        CGRectMake(0, 0, w, h-self.pointerHeight);
    
    self.shadowView.layer.shadowPath = self.menuPath.CGPath;
    self.shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    self.shadowView.layer.shadowRadius = 1.0f;
    self.shadowView.layer.shadowOpacity = 0.6f;
}

- (CGFloat)height
{
    CGFloat h = 0;
    for (id section in self.menuItems) {
        for (id item in [section objectForKey:fItems]) {
            h += ([item heightWithFont:self.font maxWidth:self.maxWidth] + self.inset*1.5);
        }
        NSString *header = [section objectForKey:fTitle];
        if (header && ![header isEqualToString:kStringNull]) {
            h+=self.headerHeight;
        }
        h+= self.footerHeight; // footer
    }
    return h;
}

- (CGFloat)width
{
    CGFloat maxWidth = 0;
    
    BOOL icons = NO;
    for (id section in self.menuItems) {
        for (id item in [section objectForKey:fItems]) {
            CGRect rect = [item boundingRectWithFont:self.font maxWidth:self.maxWidth];
            maxWidth = MAX(CGRectGetWidth(rect), maxWidth);
        }
        id header = [section objectForKey:fTitle];
        if (header) {
            CGRect rect = [header boundingRectWithFont:self.headerFont maxWidth:self.maxWidth];
            maxWidth = MAX(CGRectGetWidth(rect), maxWidth);
        }
        icons |= ([section objectForKey:fIcons]!=nil);
    }
    maxWidth += (icons ? self.iconSize + self.inset : 0) + self.inset*2.0f;
    return maxWidth;
}

+ (void) showFromFrame:(CGRect)frame
             menuItems:(NSArray*)menuItems
            completion:(SectionIndexBlock)completion
                cancel:(VoidBlock)cancel
{
    PopupMenu *menu = [[PopupMenu alloc] initWithMenuItems:menuItems];
    menu.completionHandler = completion;
    menu.cancelHandler = cancel;
    [menu showFromFrame:frame view:nil];
}

+ (void) showFromView:(id)sender
            menuItems:(NSArray*)menuItems
           completion:(SectionIndexBlock)completion
               cancel:(VoidBlock)cancel
                 rect:(CGRect)rect
{
    PopupMenu *menu = [[PopupMenu alloc] initWithMenuItems:menuItems];
    menu.completionHandler = completion;
    menu.cancelHandler = cancel;
    [menu showFromView:sender rect:rect];
}

+ (void) showFromBarButtonItem:(UIBarButtonItem*)sender
                     menuItems:(NSArray*)menuItems
                    completion:(SectionIndexBlock)completion
                        cancel:(VoidBlock)cancel
{
    PopupMenu *menu = [[PopupMenu alloc] initWithMenuItems:menuItems];
    menu.completionHandler = completion;
    menu.cancelHandler = cancel;
    [menu showFromBarButtonItem:sender];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:identifierCellContent]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void) killThisView:(VoidBlock)handler
{
    CGPoint anchorPoint = CGPointMake(self.pointerPosition/self.width, 0);
    self.transform = CGAffineTransformIdentity;
    [self setAnchorPoint:anchorPoint forView:self];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.001, 0.001);
        self.screenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.2 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.screenView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.menuView removeFromSuperview];
            [self.shadowView removeFromSuperview];
            [self removeFromSuperview];
            [self.screenView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subView, NSUInteger idx, BOOL * _Nonnull stop) {
                [subView removeFromSuperview];
            }];
            [self.screenView removeFromSuperview];
            if (handler) {
                handler();
            }
        }];
    }];
}

- (void) tappedOutside
{
    if (self.cancelHandler) {
        self.cancelHandler();
    }
    [self killThisView:nil];
}

- (void) showFromBarButtonItem:(UIBarButtonItem*)sender
{
    UIView *view = (UIView *)[sender performSelector:@selector(view)];
    [self showFromFrame:view.frame view:view];
}


- (void) showFromView:(id)sender rect:(CGRect)rect
{
    if ([sender isKindOfClass:[UIView class]]) {
        UIView *view = (UIView*) sender;
        [self showFromFrame:rect view:view];
    }
    else if ([sender isKindOfClass:[UIEvent class]]) {
        UIEvent *event = sender;
        [self showFromFrame:[event.allTouches.anyObject view].frame view:nil];
    }
    else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIView *view = (UIView *)[sender performSelector:@selector(view)];
        [self showFromFrame:view.frame view:view];
    }
    else {
        NSLog(identifierErrorMessage);
        return;
    }
}

- (void) showFromFrame:(CGRect)rect view:(UIView*)view
{
    self.screenView = [UIView new];
    self.screenView.frame = mainWindow.bounds;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    tap.delegate = self;
    [self.screenView addGestureRecognizer:tap];
    
    UIView *snapshot = nil;
    if (view) {
        snapshot = [view snapshotViewAfterScreenUpdates:YES];
        snapshot.frame = rect;
        [self.screenView addSubview:snapshot];
    }
    
    [mainWindow addSubview:self.screenView];
    [self positionMenuViewOnScreen:rect];
    
    CGPoint anchorPoint = CGPointMake(self.pointerPosition/self.width, 0);
    self.shadowView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [self setAnchorPoint:anchorPoint forView:self.shadowView];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.shadowView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        self.screenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    } completion:nil];
    if (snapshot) {
        [UIView animateWithDuration:0.2 animations:^{
            snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            snapshot.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    }
}

- (void) positionMenuViewOnScreen:(CGRect)rect
{
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGFloat screenWidth = CGRectGetWidth(mainWindow.bounds);
    CGFloat screenHeight = CGRectGetHeight(mainWindow.bounds);
    CGFloat statusBar = 0.0f;
    
    CGFloat midScreenX = CGRectGetMidX(mainWindow.bounds), midScreenY = CGRectGetMidY(mainWindow.bounds);
    
    self.direction = midY > midScreenY ? kPopupMenuDirectionUp : kPopupMenuDirectionDown;
    
    CGFloat left, right, top, bottom;
    if (midY > midScreenY) {
        bottom = minY;
        top = MAX( minY - self.height - self.pointerHeight, self.inset);
    }
    else {
        top = maxY+statusBar;
        bottom = MIN(maxY + self.height+self.pointerHeight+statusBar, screenHeight-self.inset);
    }
    
    if (midX > midScreenX) {
        right = MIN( midX + self.width / 2.0f, screenWidth - self.inset);
        left = right - self.width;
    }
    else {
        left = MAX(midX - self.width / 2.0f, self.inset);
    }
    
    self.pointerPosition = midX - left;
    self.frame = CGRectMake(left, top, self.width, bottom-top);
    [self.screenView addSubview:self];
    [self setNeedsLayout];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#define PM(__X__, __Y__) CGPointMake(__X__, __Y__)

- (UIBezierPath*) menuPath
{
    CGFloat hph = self.pointerHeight * 3.0 / 3.0f;
    CGFloat ph = self.pointerHeight;
    CGFloat h = self.height;
    CGFloat w = self.width;
    CGFloat c = self.cornerRadius;
    CGFloat m = self.pointerPosition;
    
    UIBezierPath *path = [UIBezierPath new];
    
    switch (self.direction) {
        case kPopupMenuDirectionDown:
            [path moveToPoint:PM(0, ph+c)];
            [path addQuadCurveToPoint:PM(c, ph) controlPoint:PM(0, ph)];
            [path addLineToPoint:PM(m-hph, ph)];
            [path addLineToPoint:PM(m, 0)];
            [path addLineToPoint:PM(m+hph, ph)];
            [path addLineToPoint:PM(w-c, ph)];
            [path addQuadCurveToPoint:PM(w, ph+c) controlPoint:PM(w, ph)];
            [path addLineToPoint:PM(w, ph+h-c)];
            [path addQuadCurveToPoint:PM(w-c, ph+h) controlPoint:PM(w, ph+h)];
            [path addLineToPoint:PM(c, ph+h)];
            [path addQuadCurveToPoint:PM(0, ph+h-c) controlPoint:PM(0, ph+h)];
            [path addLineToPoint:PM(0, ph+c)];
            break;
            
        default:
        case kPopupMenuDirectionUp:
            [path moveToPoint:PM(0, c)];
            [path addQuadCurveToPoint:PM(c, 0) controlPoint:PM(0, 0)];
            [path addLineToPoint:PM(w-c,0)];
            [path addQuadCurveToPoint:PM(w, c) controlPoint:PM(w, 0)];
            [path addLineToPoint:PM(w, h-c)];
            [path addQuadCurveToPoint:PM(w-c, h) controlPoint:PM(w, h)];
            [path addLineToPoint:PM(m+hph, h)];
            [path addLineToPoint:PM(m, h+ph)];
            [path addLineToPoint:PM(m-hph, h)];
            [path addLineToPoint:PM(c, h)];
            [path addQuadCurveToPoint:PM(0, h-c) controlPoint:PM(0, h)];
            [path addLineToPoint:PM(0, c)];
            break;
    }
    
    return path;
}

#undef PM

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *items = self.menuItems[section][fItems];
    return items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;
    
    PopupMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierMenuCell forIndexPath:indexPath];

    id item, icon, image, title = nil;
    NSArray *items = self.menuItems[section][fItems];
    NSArray *icons = self.menuItems[section][fIcons];
    item = items[row];
    icon = icons[row];
    image = [UIImage imageNamed:icon];
    title = self.menuItems[section][fTitle];
    [cell setMenuItem:item
                 icon:image
                 font:self.font
                inset:self.inset
             iconSize:self.iconSize
            separator:(indexPath.row > 0) || (section >0 && [title isEqualToString:kStringNull])
            textColor:self.textColor
        textAlignment:self.textAlignment
       separatorColor:self.separatorColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    id item;
    NSArray *items = self.menuItems[section][fItems];
    item = items[row];

    return ([item heightWithFont:self.font maxWidth:self.maxWidth] + self.inset*1.5);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return self.footerHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = self.menuItems[section][fTitle];
    if (!header)
        return 0;
    
    return ([header isEqualToString:kStringNull]) ? 0 : self.headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *header = self.menuItems[section][fTitle];
    if (!header)
        return nil;
    
    UIView *view = [UIView new];
    view.frame = CGRectMake(0, 0, self.width, self.headerHeight);
    
    UILabel *headr = [UILabel new];
    headr.frame = CGRectMake(self.inset,
                             0,
                             self.width-2.0f*self.inset,
                             self.headerHeight);
    headr.backgroundColor = [UIColor clearColor];
    headr.font = self.headerFont;
    headr.textColor = [UIColor darkTextColor];
    headr.text = [self.menuItems[section][fTitle] uppercaseString];
    headr.textAlignment = NSTextAlignmentCenter;
    
    [view addSubview:headr];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    id item;

    NSArray *items = self.menuItems[section][fItems];
    item = items[row];

    [self killThisView:^{
        if (self.completionHandler) {
            self.completionHandler(indexPath.section, indexPath.row);
        }
    }];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.menuView.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor
{
    return self.menuView.backgroundColor;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
