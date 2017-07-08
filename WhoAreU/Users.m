//
//  Users.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Users.h"
#import "Refresh.h"
#import "BlurView.h"
#import "Segment.h"
#import "UserCell.h"
#import "MessageCenter.h"
#import "Chat.h"
#import "Profile.h"
#import "HeaderMenu.h"
#import "TabBar.h"
#import "MessageView.h"

#define kUserCell @"UserCell"
#define kLoadMoreCell @"LoadMoreCell"

@interface Users () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray <User*> *users;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) Refresh *refresh;
@property (nonatomic) NSUInteger skip, limit;
@property (nonatomic) SegmentType segmentIndex;
@property (nonatomic) NearBySortBy sortby;
@property (strong, nonatomic) BlurView *sectionView;
@property (weak, nonatomic) IBOutlet Segment *segmentSort;
@property (weak, nonatomic) IBOutlet Segment *segmentUsers;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@property (strong, nonatomic) NSArray <NSString*> *selectionMenu, *sortbyMenu;
@end

@implementation Users

- (void)viewDidAppear:(BOOL)animated
{
    __LF
}

- (void)viewWillAppear:(BOOL)animated
{
    __LF
}

- (void)viewDidDisappear:(BOOL)animated
{
    __LF
}

- (void)viewWillDisappear:(BOOL)animated
{
    __LF
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedRow = -1;
    Notification(kNotificationSystemInitialized, systemInitialized:);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
//    self.tableView.contentInset = UIEdgeInsetsMake(self.heightConstraint.constant, 0, 2*49.f, 0);
    [self.tableView registerNibsNamed:@[kUserCell, kLoadMoreCell]];
    
    self.refresh = [Refresh initWithCompletionBlock:^(UIRefreshControl *refreshControl) {
        [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    }];
//    [self.tableView addSubview:self.refresh];
    
    self.selectionMenu = @[
                           @"Girls",
                           @"Boys",
                           @"All",
                           @"Likes",
                           ];
    self.sortbyMenu = @[
                        @" - GPS",
                        @" - TIME",
                        ];
    
    self.sortby = kNearBySortByLocation;
    self.segmentIndex = 0;
    self.skip = 0;
    self.limit = 20;
    
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    [self setupSegments];
    
    UIView *segView = [UIView new];
    segView.backgroundColor = [UIColor redColor];
    segView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60.f);
    
    TabBar *seg = [TabBar new];
    seg.gradientOn = NO;
    seg.items = @[
                      @{
                          fTitle : @"Users",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          },
                      @{
                          //                          fTitle : @"Me",
                          fIcon : @"user",
                          fDeselectedIcon : @"user",
                          },
                      @{
                          //                          fTitle : @"Me",
                          fIcon : @"heart",
                          fDeselectedIcon : @"heart",
                          },
                      @{
                          //                          fTitle : @"Chat",
                          fIcon : @"message2",
                          fDeselectedIcon : @"message2",
                          },
                      @{
                          //                          fTitle : @"Channel",
                          fIcon : @"pin2",
                          fDeselectedIcon : @"pin2",
                          },
                      ];
    
    seg.index = 2;
    seg.frame = CGRectInset(segView.bounds, 10, 5);

    [segView addSubview:seg];
//    HeaderMenu *menu = [HeaderMenu menuWithView:segView];
    HeaderMenu *menu = [HeaderMenu menuWithTabBarItems:@[
                                                         @{
                                                             fTitle : @"Users",
                                                             fIcon : @"pin",
                                                             fDeselectedIcon : @"pin",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Me",
                                                             fIcon : @"user",
                                                             fDeselectedIcon : @"user",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Me",
                                                             fIcon : @"heart",
                                                             fDeselectedIcon : @"heart",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Chat",
                                                             fIcon : @"message2",
                                                             fDeselectedIcon : @"message2",
                                                             },
                                                         @{
                                                             //                          fTitle : @"Channel",
                                                             fIcon : @"pin2",
                                                             fDeselectedIcon : @"pin2",
                                                             },
                                                         ]];
    
    menu.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60.f);
    menu.backgroundColor = [UIColor redColor];
    [self.tableView addSubview:menu];
    
//    self.tableView.backgroundColor = [UIColor blackColor];
}

- (IBAction)selectSortby:(UIBarButtonItem*)sender
{
    self.sortby = !self.sortby;
    
    [sender setImage:self.sortby ? [UIImage imageNamed:@"gps"] : [UIImage imageNamed:@"timelapse"]];
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    
    MessageView *mv = [MessageView new];
    mv.title = @"Hello";
    mv.message = @"This is a system message. This is a system message. This is a system message. This is a system message. This is a system message. This is a system message.";
    mv.backgroundColor = [UIColor appColor];
    
    [mv addButton:@"OK" action:^(){
        __LF
    } backgroundColor:mv.backgroundColor.lighterColor textColor:nil];
    [mv addCancelButton:nil action:^{
        __LF
    } backgroundColor:nil textColor:nil];
    
//    [mv addButton:@"CANCEL" action:^(){
//        __LF
//    } backgroundColor:mv.backgroundColor.darkerColor textColor:nil];
    
    [mv show];
}

- (void) setupSegments
{
    self.segmentUsers.select = self.tabConditionSelected;
    //    self.segmentUsers.backgroundColor = [UIColor femaleColor];
    self.segmentUsers.items = @[
                                @"Girls",
                                @"Boys",
                                @"All",
                                @"Likes"
                                ];
    [self.segmentUsers equalizeWidth];
    
    self.segmentSort.select = self.locationConditionSelected;
    //    self.segmentSort.backgroundColor = [UIColor maleColor];
    self.segmentSort.items = @[
                               @"GPS",
                               @"Time",
                               ];
    [self.segmentSort equalizeWidth];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)setSortby:(NearBySortBy)sortby
{
    _sortby = sortby;
    [self setNavigationTitle];
}

- (void)setSegmentIndex:(SegmentType)segmentIndex
{
    _segmentIndex = segmentIndex;
    [self setNavigationTitle];
}

- (void)setNavigationTitle
{
    self.navigationItem.title = [self.selectionMenu[self.segmentIndex] stringByAppendingString:self.sortbyMenu[self.sortby]];
}

- (void)reloadAllUsersOnCondition:(SegmentType)segmentIndex reset:(BOOL)reset
{
    self.selectedRow = -1;
    [self.tableView reloadData];
    
    if (!reset && ![self.refresh isRefreshing]) {
        [self.refresh beginRefreshing];
    }
    
    [self usersNear:[User me] completionHandler:^(NSArray<User *> *users) {
        if (reset) {
            self.skip = 0;
            self.users = users;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        else {
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.users];
            [array addObjectsFromArray:users];
            self.users = array;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        [self.refresh endRefreshing];
    } condition:segmentIndex];
}

- (void)usersNear:(User*)user completionHandler:(ArrayBlock)block condition:(SegmentType)segmentIndex
{
    PFQuery *query = [User query];
    [query setSkip:self.skip];
    [query setLimit:self.limit];
    [query includeKey:fMedia];
    
    //  No need to include keys... lazy loading when tapped.
    //  [query includeKey:fPhotos];
    
    switch (segmentIndex) {
        case kSegmentGirls:
            [query whereKey:@"gender" equalTo:@(kGenderTypeFemale)];
            break;
        case kSegmentBoys:
            [query whereKey:@"gender" equalTo:@(kGenderTypeMale)];
            break;
        case kSegmentAll:
            break;
        case kSegmentLikes: {
            NSArray *likes = [User me].likes;
            [query whereKey:fObjectId containedIn:[likes valueForKey:fObjectId]];
        }
            break;
        default:
            break;
    }
    if ([User me]) {
        [query whereKey:fObjectId notEqualTo:[User me].objectId];
        if (self.sortby == kNearBySortByLocation) {
            [query whereKey:fWhere nearGeoPoint:[User where]];
        }
        else {
            [query orderByDescending:fUpdatedAt];
        }
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users, NSError * _Nullable error) {
            if (error) {
                LogError;
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (block) {
                        block(users);
                    }
                });
            }
        }];
    });
}

- (void)systemInitialized:(id)sender
{
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==kSectionUsers)
        return self.users.count;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionUsers) {
        UserCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCell forIndexPath:indexPath];
 
        User *user = [self.users objectAtIndex:indexPath.row];
        
        cell.parent = self;
        cell.user = user;
        
        return cell;
    }
    else {
        NSLog(@"No more cell at %ld", indexPath.row);
        NoMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:kLoadMoreCell forIndexPath:indexPath];
        
        if (self.users.count == self.skip + self.limit) {
            cell.label.text = @"Load More";
        }
        else {
            cell.label.text = @"No More";
        }
        return cell;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Chat"]) {
        // other preparations.
        Chat *chat = segue.destinationViewController;
        chat.hidesBottomBarWhenPushed = YES;
        chat.dictionary = sender;
    }
    else if ([segue.identifier isEqualToString:@"Profile"]) {
        Profile *profile = segue.destinationViewController;
        profile.hidesBottomBarWhenPushed = YES;
        if ([sender isKindOfClass:[User class]]) {
            profile.user = sender;
        }
        else {
            __alert(@"ERROR", @"Wrong sender", nil, nil, self);
            profile.user = [User me];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [self.users objectAtIndex:indexPath.row];
    UIFont *font = kIntroductionFont;
    NSString *intro = user.introduction;
    CGFloat w = CGRectGetWidth(self.tableView.bounds);
    CGFloat y = 55;
    CGFloat x = 66+8;
    CGFloat i = 8, s = 30;
    CGFloat mw = w - x - i*2 - s;
    CGFloat h = [intro heightWithFont:font maxWidth:mw];
    
    CGFloat rowHeight = y + h + i+8;
    
    if (indexPath.section == kSectionUsers) {
        return rowHeight + ((indexPath.row == self.selectedRow) ? 52.f : 4.f);
    }
    else {
        // more cells...
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionUsers) {
        static UserCell* prevCell = nil;
        
        UserCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (indexPath.row == self.selectedRow) {
            self.selectedRow = -1;
            cell.selected = NO;
            
            [cell tapped:cell];
        }
        else {
            prevCell.selected = NO;
            prevCell = cell;
            self.selectedRow = indexPath.row;
            cell.selected = YES;
            
            [cell tapped:cell];
        }
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    else {
        self.skip += self.limit;
        [self reloadAllUsersOnCondition:self.segmentIndex reset:NO];
    }
}

#define TabHeight 40.f
#define TabInset 8.f
#define TabHalfInset 4.0f
#define LocationButtonWidth 60.f
#define LocationWidth (2*LocationButtonWidth+TabHalfInset)

- (void (^)(NSUInteger index))tabConditionSelected
{
    return ^(NSUInteger index) {
        self.segmentIndex = index;
        self.skip = 0;
        [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    };
}

- (void (^)(NSUInteger index))locationConditionSelected
{
    return ^(NSUInteger index) {
        self.sortby = index;
        [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    };
}

@end
