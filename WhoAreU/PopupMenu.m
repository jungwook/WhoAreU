//
//  PopupMenu.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 26..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PopupMenu.h"

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
        self.menuLabel.frame = CGRectMake(self.inset*2,
                                          0,
                                          w-3*self.inset,
                                          h);
    }
    if (self.separatorLine) {
        CGFloat add = self.image ? self.inset + self.iconSize : 0;
        self.separatorLine.frame = CGRectMake(self.inset*2 + add,
                                              0,
                                              w-3*self.inset-add,
                                              0.5);
    }
}

@end

@interface PopupMenu () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, readonly) CGFloat inset, maxWidth, width, height, iconSize, pointerHeight, cornerRadius, headerHeight;
@property (nonatomic) PopupMenuDirection direction, pointerPosition;
@property (nonatomic, strong) UIView* menuView, *screenView, *shadowView;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, copy) IndexBlock completionHandler;
@property (nonatomic, copy) VoidBlock cancelHandler;
@property (nonatomic) BOOL simple;
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
        self.icons = nil;
    }
    return self;
}

- (instancetype)initWithMenuItems:(NSArray*)menuItems icons:(NSArray*)icons
{
    self = [super init];
    if (self) {
        [self setupVariables];
        self.menuItems = menuItems;
        self.icons = icons;
    }
    return self;
}

- (void) setupVariables
{
    self.font = [UIFont systemFontOfSize:13];
    _headerHeight = 30.0f;
    _inset = 8.0f;
    _maxWidth = 140.0f;
    _iconSize = 20.0f;
    _pointerHeight = 10.0f;
    _direction = kPopupMenuDirectionDown;
    _cornerRadius = 8.0f;
    _separatorColor = [UIColor groupTableViewBackgroundColor];
    _textColor = [UIColor darkGrayColor];
    _textAlignment = NSTextAlignmentLeft;

    self.menuView = [UIView new];
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
    
    [self.tableView registerClass:[PopupMenuCell class] forCellReuseIdentifier:@"MenuCell"];
    
    self.menuView.clipsToBounds = YES;
    [self.menuView addSubview:self.tableView];
    
    [self addSubview:self.shadowView];
    [self.shadowView addSubview:self.menuView];
}

- (void)setMenuItems:(NSArray *)menuItems
{
    _menuItems = menuItems;
    
    self.simple = [[self.menuItems firstObject] isKindOfClass:[NSString class]];
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
    self.shadowView.layer.shadowOffset = CGSizeMake(2, 2);
    self.shadowView.layer.shadowRadius = 2.0f;
    self.shadowView.layer.shadowOpacity = 0.6f;
}

- (CGFloat)height
{
    CGFloat h = 0;
    if (self.simple) {
        for (id menuItem in self.menuItems) {
            h += ([menuItem heightWithFont:self.font maxWidth:self.maxWidth] + 2*self.inset);
        }
        return h;
    }
    else {
        for (id section in self.menuItems) {
            for (id item in [section objectForKey:@"items"]) {
                h += ([item heightWithFont:self.font maxWidth:self.maxWidth] + 2*self.inset);
            }
            if (![[section objectForKey:@"title"] isEqualToString:@""]) {
                h+=self.headerHeight;
            }
        }
        return h;
    }
}

- (CGFloat)width
{
    CGFloat maxWidth = 0;
    
    if (self.simple) {
        for (id menuItem in self.menuItems) {
            CGRect rect = [menuItem boundingRectWithFont:self.font maxWidth:self.maxWidth];
            CGFloat w = CGRectGetWidth(rect);
            maxWidth = w > maxWidth ? w : maxWidth;
        }
        // insets on each side
        maxWidth += 3*self.inset + (self.icons ? self.iconSize : 0);
        return maxWidth;
    }
    else {
        for (id section in self.menuItems) {
            for (id item in [section objectForKey:@"items"]) {
                CGRect rect = [item boundingRectWithFont:self.font maxWidth:self.maxWidth];
                CGFloat w = CGRectGetWidth(rect);
                maxWidth = w > maxWidth ? w : maxWidth;
            }
        }
        // insets on each side
        maxWidth += 3*self.inset + (self.icons ? self.iconSize : 0);
        return maxWidth;
    }
}

+ (void) showFromFrame:(CGRect)frame
             menuItems:(NSArray*)menuItems
            completion:(IndexBlock)completion
                cancel:(VoidBlock)cancel
{
    [self showFromFrame:frame menuItems:menuItems icons:nil completion:completion cancel:cancel];
}

+ (void) showFromFrame:(CGRect)frame
             menuItems:(NSArray*)menuItems
                 icons:(NSArray*)icons
            completion:(IndexBlock)completion
                cancel:(VoidBlock)cancel
{
    PopupMenu *menu = [[PopupMenu alloc] initWithMenuItems:menuItems icons:icons];
    menu.completionHandler = completion;
    menu.cancelHandler = cancel;
    [menu showFromFrame:frame];
}

+ (void) showFromView:(id)sender
            menuItems:(NSArray*)menuItems
           completion:(IndexBlock)completion
               cancel:(VoidBlock)cancel
{
    [self showFromView:sender menuItems:menuItems icons:nil completion:completion cancel:cancel];
}

+ (void) showFromView:(id)sender
            menuItems:(NSArray*)menuItems
                icons:(NSArray*)icons
           completion:(IndexBlock)completion
               cancel:(VoidBlock)cancel
{
    PopupMenu *menu = [[PopupMenu alloc] initWithMenuItems:menuItems icons:icons];
    menu.completionHandler = completion;
    menu.cancelHandler = cancel;
    [menu showFromView:sender];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void) killThisView
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
            [self.screenView removeFromSuperview]; 
        }];
    }];
}

- (void) tappedOutside
{
    if (self.cancelHandler) {
        self.cancelHandler();
    }
    [self killThisView];
}

- (void) showFromView:(id)sender
{
    if ([sender isKindOfClass:[UIView class]]) {
        [self showFromFrame:((UIView*)sender).frame];
    }
    else if ([sender isKindOfClass:[UIEvent class]]) {
        UIEvent *event = sender;
        [self showFromFrame:[event.allTouches.anyObject view].frame];
    }
    else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIView *view = (UIView *)[sender performSelector:@selector(view)];
        [self showFromFrame:view.frame];
    }
    else {
        NSLog(@"PopupMenu: unknown sender class to start menu.");
        return;
    }
}

- (void) showFromFrame:(CGRect)rect
{
    self.screenView = [UIView new];
    self.screenView.frame = mainWindow.bounds;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    tap.delegate = self;
    [self.screenView addGestureRecognizer:tap];
    
    [mainWindow addSubview:self.screenView];
    [self positionMenuViewOnScreen:rect];
    
    CGPoint anchorPoint = CGPointMake(self.pointerPosition/self.width, 0);
    self.shadowView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [self setAnchorPoint:anchorPoint forView:self.shadowView];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.shadowView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        self.screenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
    } completion:nil];
}

- (void) positionMenuViewOnScreen:(CGRect)rect
{
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGFloat screenWidth = CGRectGetWidth(mainWindow.bounds);
    CGFloat screenHeight = CGRectGetHeight(mainWindow.bounds);
    CGFloat statusBar = 20.0f;
    
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
    CGFloat hph = self.pointerHeight * 2.0 / 3.0f;
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
    if (self.simple) {
        return self.menuItems.count;
    }
    else {
        NSArray *items = self.menuItems[section][@"items"];
        return items.count;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.simple) {
        return 1;
    }
    else {
        return self.menuItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;
    
    PopupMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];

    id item, icon, image, title = nil;
    if (self.simple) {
        item = self.menuItems[row];
        icon = self.icons[row];
        image = [UIImage imageNamed:icon];
    }
    else {
        NSArray *items = self.menuItems[section][@"items"];
        NSArray *icons = self.icons[section];
        item = items[row];
        icon = icons[row];
        image = [UIImage imageNamed:icon];
        title = self.menuItems[section][@"title"];
    }
    [cell setMenuItem:item
                 icon:image
                 font:self.font
                inset:self.inset
             iconSize:self.iconSize
            separator:(indexPath.row > 0) || (section >0 && [title isEqualToString:@""])
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
    if (self.simple) {
        item = self.menuItems[row];
    }
    else {
        NSArray *items = self.menuItems[section][@"items"];
        item = items[row];
    }

    return ([item heightWithFont:self.font maxWidth:self.maxWidth] + 2*self.inset);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (self.simple) ? 0 : ([self.menuItems[section][@"title"] isEqualToString:@""]) ? 0 : self.headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.simple) {
        return nil;
    }
    else {
        UIView *view = [UIView new];
        view.frame = CGRectMake(0, 0, self.width, self.headerHeight);
        
        UILabel *headr = [UILabel new];
        headr.frame = CGRectMake(self.inset, self.inset, self.width-self.inset, self.headerHeight - self.inset);
        headr.backgroundColor = [UIColor clearColor];
        headr.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        headr.textColor = [UIColor darkTextColor];
        headr.text = [self.menuItems[section][@"title"] uppercaseString];
        
        [view addSubview:headr];
        return view;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    id item;
    if (self.simple) {
        item = self.menuItems[row];
    }
    else {
        NSArray *items = self.menuItems[section][@"items"];
        item = items[row];
    }

    NSLog(@"selected:%@", item);
    
    if (self.completionHandler) {
        self.completionHandler(indexPath.section, indexPath.row);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self killThisView];
    });
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
