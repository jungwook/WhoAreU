//
//  PageTab.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PageTab.h"
#import "TabBar.h"
#import "MessageCenter.h"

@interface FloatingActionMenuItemCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *snapshot;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, assign) NSString *title;
@property (nonatomic, strong) UIImage *image;
@end

@implementation FloatingActionMenuItemCell

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

- (void)layoutSubviews
{
    CGFloat size = 25;
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    self.label.frame = CGRectMake(0, h-size, w, size);
    self.snapshot.frame = CGRectMake(0, 0, w, h-40);
}

- (CGFloat) factor
{
    return 2.5f;
}

-(void)setTitle:(NSString *)title
{
    self.label.text = title;
}

- (void)setupVariables
{
    self.label = [UILabel new];
    self.label.font = [UIFont boldSystemFontOfSize:20];
    self.label.textColor = [UIColor whiteColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.label];
    
    self.snapshot = [UIImageView new];
    self.snapshot.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self addSubview:self.snapshot];
}

- (void)setImage:(UIImage *)image
{
    self.snapshot.image = image;
}

@end

@interface PageTab () <UITabBarDelegate>
@property (weak, nonatomic) IBOutlet TabBar *tabs;
@property (strong, nonatomic) NSArray<UIViewController*> *viewControllers;
@property (strong, nonatomic) NSArray<NSMutableDictionary*> *tabItems;
@property (strong, nonatomic) NSMutableDictionary<id, UIView*> *snapshotImages;
@property (nonatomic) NSUInteger index;


// Menu system
@property (nonatomic, strong) UIButton *floatingActionButton;
@property (nonatomic, strong) UIView* backgroundView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, readonly) CGFloat factor;
@property (nonatomic, readonly) CGRect itemRect;
@end

@implementation PageTab

- (CGFloat)factor
{
    return 2.5f;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#define VC(__I__) [self.storyboard instantiateViewControllerWithIdentifier:__I__]

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupFloatingActionButton];
    [self setupBackgroundView];

    self.tabs.equalWidth = NO;
    self.tabItems = @[
                      @{
                          fTitle : @"Pins",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Cluster"),
                          fNavigationControllerNotRequired : @(YES),
                          },
                      @{
                          fTitle : @"Location",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Location"),
                          },
                      @{
                          fTitle : @"Users",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Cards"),
                          fNavigationControllerNotRequired : @(YES),
                          },
                      @{
//                          fTitle : @"Users",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Users"),
                          },
                      @{
//                          fTitle : @"Me",
                          fIcon : @"user",
                          fDeselectedIcon : @"user",
                          fViewController : VC(@"ProfileMain"),
                          },
                      @{
//                          fTitle : @"Me",
                          fIcon : @"heart",
                          fDeselectedIcon : @"heart",
                          fViewController : VC(@"UserProfile"),
                         },
                      @{
//                          fTitle : @"Chat",
                          fIcon : @"message2",
                          fDeselectedIcon : @"message2",
                          fViewController : VC(@"Chats"),
                          },
                      @{
//                          fTitle : @"Channel",
                          fIcon : @"pin2",
                          fDeselectedIcon : @"pin2",
                          fViewController : VC(@"Channels"),
                          },
                ];
    
    
    self.tabs.position = kTabBarIndicatorPositionTop;
    self.tabs.selectAction = ^(NSUInteger index) {
        UIPageViewControllerNavigationDirection direction = index > self.index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        self.index = index;
        [self.pages setViewControllers:@[self.viewControllers[index]] direction:direction animated:YES completion:nil];
    };
    
    self.tabs.backgroundColor = [UIColor whiteColor];
    self.tabs.blurOn = YES;
    self.tabs.selectedColor = [UIColor appColor];
    self.tabs.deselectedColor = [[UIColor appColor] colorWithAlphaComponent:0.4];
    self.tabs.indicatorColor = [UIColor appColor];
}

- (void)setupFloatingActionButton
{
    const CGFloat size = 40;
    self.floatingActionButton = [UIButton new];
    self.floatingActionButton.frame = CGRectMake(20, 40, size, size);
    [self.floatingActionButton setTitle:@"+" forState:UIControlStateNormal];
    self.floatingActionButton.radius = size/2.0f;
    self.floatingActionButton.clipsToBounds = YES;
    self.floatingActionButton.backgroundColor = [UIColor redColor];
    
    [self.floatingActionButton addTarget:self action:@selector(tappedFloatingAction:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:self.floatingActionButton];
}

- (void)setupBackgroundView
{
    self.snapshotImages = [NSMutableDictionary dictionary];
    
    self.backgroundView = [UIView new];
    self.backgroundView.frame = mainWindow.bounds;
    self.backgroundView.backgroundColor = [UIColor blackColor];
    
    CGFloat w = CGRectGetWidth(mainWindow.bounds), h = CGRectGetHeight(mainWindow.bounds);
    CGFloat itemWidth = CGRectGetWidth(self.itemRect), itemHeight = CGRectGetHeight(self.itemRect);
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = self.itemRect.size;
    layout.sectionInset = UIEdgeInsetsMake((h-itemHeight)/2.0f, (w-itemWidth)/2.0f, (h-itemHeight)/2.0f, (w-itemWidth)/2.0f);
    layout.minimumLineSpacing = 50.0f;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:mainWindow.bounds collectionViewLayout:layout];
    
    [self.collectionView registerClass:[FloatingActionMenuItemCell class] forCellWithReuseIdentifier:fViewController];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.backgroundView addSubview:self.collectionView];
    
    [self.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)]];
}

- (void) tappedOutside:(id)sender
{
    [self.pages setViewControllers:@[self.viewControllers[self.tabs.index]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    [self.backgroundView removeFromSuperview];
}

- (UIImage*)viewAsImage:(UIView*)view
{
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)tappedFloatingAction:(UIButton*)button
{
    self.backgroundView.alpha = 1;
    self.collectionView.alpha = 0;
    [mainWindow addSubview:self.backgroundView];
    
    UIView *snapshot = [mainWindow snapshotViewAfterScreenUpdates:NO];
    [mainWindow addSubview:snapshot];
    
    __LF
    
    setAnchorPoint(CGPointMake(0.5, 0.5), snapshot);
    [UIView animateWithDuration:0.5f animations:^{
        CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1/self.factor, 1/self.factor);
        transform = CGAffineTransformTranslate(transform, 0, -50);
        snapshot.transform = transform;
        snapshot.alpha = 0.5f;
        self.collectionView.alpha = 0.5f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.collectionView.alpha = 1.0f;
            snapshot.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
        }];
    }];
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.tabItems.count;
}

- (CGRect)itemRect
{
    CGFloat w = CGRectGetWidth(mainWindow.bounds), h = CGRectGetHeight(mainWindow.bounds);
    return CGRectMake(0, 0, w/self.factor, h/self.factor + 40.f);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FloatingActionMenuItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:fViewController forIndexPath:indexPath];
    
    id item = [self.tabItems objectAtIndex:indexPath.row];
    
    cell.title = item[fTitle] ?: @"Dummy";
    UIView *snapshot = [self renderedSnapshotForRow:indexPath.row];
    NSLog(@"SNAPSHOT:%@", snapshot);
    [cell addSubview:snapshot];
    
    return cell;
}

- (UIView*)renderedSnapshotForRow:(NSUInteger)row
{
    UIView *snapshot = [self.snapshotImages objectForKey:@(row)];
    [snapshot removeFromSuperview];
    setAnchorPoint(CGPointZero, snapshot);
    snapshot.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1/self.factor, 1/self.factor);
    
    return snapshot;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"IndexPath:%@", indexPath);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MessageCenter startFromViewController:self];
}

-(void)setTabItems:(NSArray *)tabItems
{
    NSMutableArray *viewControllers = [NSMutableArray new];
    _tabItems = tabItems;
    
    self.tabs.items = self.tabItems;
    [self.tabItems enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController* vc = [tabItem objectForKey:fViewController];
        BOOL navigationControllerNotRequired = [[tabItem objectForKey:fNavigationControllerNotRequired] boolValue] == YES;
        if (!navigationControllerNotRequired && ![vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
            [viewControllers addObject:nc];
        }
        else {
            [viewControllers addObject:vc];
        }
    }];
    
    [self.tabItems enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController *viewController = tabItem[fViewController];
//        [viewController loadView];
        [self.pages setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
            UIView *view = viewController.view;
            [self.snapshotImages setObject:[view snapshotViewAfterScreenUpdates:YES] forKey:@(idx)];
        }];
    }];
    
    [self.collectionView reloadData];
    self.viewControllers = viewControllers;
    [self.pages setViewControllers:@[self.viewControllers.firstObject] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    __LF
    if ([segue.identifier isEqualToString:@"Pages"]) {
        self.pages = segue.destinationViewController;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
