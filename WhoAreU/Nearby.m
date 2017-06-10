//
//  Nearby.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 18..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Nearby.h"
#import "Profile.h"
#import "PhotoView.h"
#import "CompassView.h"
#import "IndentedLabel.h"
#import "UserProfile.h"
#import "Chat.h"
#import "Refresh.h"
#import "MediaCollection.h"
#import "BalloonLabel.h"
#import "MessageCenter.h"
#import "UserCell.h"
#import "BlurView.h"
#import "SelectionTab.h"

#define kUserCell @"UserCell"
#define kLoadMoreCell @"LoadMoreCell"

@interface Nearby ()
@property (strong, nonatomic) NSArray <User*> *users;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) Refresh *refresh;
@property (nonatomic) NSUInteger skip, limit;
@property (nonatomic) SegmentType segmentIndex;
@property (nonatomic) NearBySortBy sortby;
@property (strong, nonatomic) BlurView *sectionView;
@property (strong, nonatomic) SelectionTab *tab, *location;
@property (strong, nonatomic) NSArray <NSString*> *selectionMenu, *sortbyMenu;
@end

@implementation Nearby

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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.tableView registerNib:[UINib nibWithNibName:kUserCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kUserCell];
    [self.tableView registerNib:[UINib nibWithNibName:kLoadMoreCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kLoadMoreCell];

    self.selectionMenu = @[
                           @"Girls",
                           @"Boys",
                           @"All",
                           @"Favorites",
                           ];
    self.sortbyMenu = @[
                        @" - near",
                        @" - recent",
                        ];

    self.sortby = kNearBySortByLocation;
    self.segmentIndex = 0;
    self.skip = 0;
    self.limit = 200;
    self.refresh = [Refresh initWithCompletionBlock:^(UIRefreshControl *refreshControl) {
        [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    }];
    [self.tableView addSubview:self.refresh];
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
        }
        else {
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.users];
            [array addObjectsFromArray:users];
            self.users = array;
        }
        [self.refresh endRefreshing];
        [self.tableView reloadData];
    } condition:segmentIndex];
}

- (NSArray*) sortUsersByDistance:(NSArray*) users
{
    User *user = [User me];
    return [users sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        PFGeoPoint *p1 = ((User*)obj1).where;
        PFGeoPoint *p2 = ((User*)obj2).where;
        
        CGFloat distanceA = [user.where distanceInKilometersTo:p1];
        CGFloat distanceB = [user.where distanceInKilometersTo:p2];
        
        if (distanceA < distanceB) {
            return NSOrderedAscending;
        } else if (distanceA > distanceB) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (NSArray*) arrayOfUserIds:(NSArray*)users
{
    NSMutableArray *userIds = [NSMutableArray array];
    [users enumerateObjectsUsingBlock:^(User* _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        [userIds addObject:user.objectId];
    }];
    return userIds;
}

- (void)usersNear:(User*)user completionHandler:(ArrayBlock)block condition:(SegmentType)segmentIndex
{
    __LF
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
        case kSegmentLikes:
            [query whereKey:fObjectId containedIn:[self arrayOfUserIds:[User me].likes]];
            break;
        default:
            break;
    }
    [query whereKey:fObjectId notEqualTo:[User me].objectId];
    if (self.sortby == kNearBySortByLocation) {
        NSLog(@"Querying location:%@", [User where]);
        [query whereKey:fWhere nearGeoPoint:[User where]];
    }
    else {
        NSLog(@"Querying by time");
        [query orderByDescending:fUpdatedAt];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users, NSError * _Nullable error) {
        if (error) {
            LogError;
        }
        else {
            if (block) {
                block(users);
            }
        }
    }];
}

- (void)systemInitialized:(id)sender
{
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedRow = -1;
    Notification(kNotificationSystemInitialized, systemInitialized:);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
        
        __weak typeof(UserCell*) weakCell = cell;
        
        User *user = [self.users objectAtIndex:indexPath.row];
        
        cell.parent = self;
        cell.user = user;
        cell.chatAction = ^(User *user) {
            // actions
            [User payForChatWithUser:user onViewController:self action:^(id object) {
                if ([object isKindOfClass:[Channel class]]) {
                    Channel *channel = object;
                    [self performSegueWithIdentifier:@"Chat" sender:channel.dictionary];
                    weakCell.badgeValue = nil;
                }
                else if ([object isKindOfClass:[NSString class]]) {
                    NSLog(@"FIRST MESSAGE:%@", object);
                    [MessageCenter send:object users:@[user] completion:^(Channel *channel) {
                        NSLog(@"Entering Chat with channel:%@", channel.dictionary);
                        [self performSegueWithIdentifier:@"Chat" sender:channel.dictionary];
                        weakCell.badgeValue = nil;
                    }];
                }
                else {
                    NSLog(@"ERROR[%s]:Unknown return", __func__);
                }
            }];
        };
        
        return cell;
    }
    else {
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
    if ([segue.identifier isEqualToString:@"UserProfile"]) {
        UserProfile *vc = segue.destinationViewController;
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        vc.user = sender;
    }
    else if ([segue.identifier isEqualToString:@"Chat"]) {
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
        return rowHeight + ((indexPath.row == self.selectedRow) ? 50.f : 0.f);
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

#define TabHeight 50.f
#define TabInset 8.f
#define TabHalfInset 4.0f
#define LocationButtonWidth 60.f
#define LocationWidth (2*LocationButtonWidth+TabHalfInset)

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section==kSectionUsers)
        return TabHeight+TabInset+TabInset;
    else
        return 0.0f;
}

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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.sectionView)
        return self.sectionView;
    
    CGRect rect = self.tableView.frame;
    CGFloat w = CGRectGetWidth(rect);
    
    self.sectionView = [BlurView new];
    self.tab = [SelectionTab newWithTabs:@[
                                           @"Girls\nOnly",
                                           @"Boys\nOnly",
                                           @"All\nUsers",
                                           @"Favorites"
                                           ]
                                  widths:@[
                                           @(1),
                                           @(1),
                                           @(1),
                                           @(1.3),
                                           ]
                action:self.tabConditionSelected];

    self.location = [SelectionTab newWithTabs:@[
                                                @"near",
                                                @"recent",
                                                ]
                                       widths:@[
                                                @(1),
                                                @(1),
                                                ]
                                       colors:@[
                                                [UIColor greenColor].darkerColor,
                                                [UIColor greenColor],
                                                ]
                                       action:self.locationConditionSelected];
    
    self.location.frame = CGRectMake(TabInset,
                                     TabInset,
                                     LocationWidth,
                                     TabHeight);
    self.tab.frame = CGRectMake(TabInset+LocationWidth+TabHalfInset,
                                TabInset,
                                w-2*TabInset-LocationWidth-TabHalfInset,
                                TabHeight);

    [self.sectionView addSubview:self.tab];
    [self.sectionView addSubview:self.location];
    
    self.sectionView.frame = CGRectMake(0, 0, w, TabHeight+TabInset*2);
    self.sortby = kNearBySortByLocation;
    
    return self.sectionView;
}

- (void) selectSortBy:(UIButton*)sender
{
    self.sortby = sender.tag;
    
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.segmentIndex == kSegmentLikes) {
        return YES;
    }
    else
        return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"UNLIKE";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRow = -1;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
