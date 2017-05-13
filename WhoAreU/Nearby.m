//
//  Nearby.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 18..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Nearby.h"
#import "PhotoView.h"
#import "Compass.h"
#import "IndentedLabel.h"
#import "UserProfile.h"
#import "Chat.h"
#import "Refresh.h"
#import "MediaCollection.h"
#import "BalloonLabel.h"
#import "MessageCenter.h"

@interface NoMoreCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation NoMoreCell


@end

@interface UserCell : UITableViewCell
@property (weak, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *desc;
@property (weak, nonatomic) IBOutlet IndentedLabel *gender;
@property (weak, nonatomic) IBOutlet IndentedLabel *age;
@property (weak, nonatomic) IBOutlet IndentedLabel *ago;
@property (weak, nonatomic) IBOutlet UserView *userView;
@property (weak, nonatomic) IBOutlet Compass *compass;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *like;
@property (weak, nonatomic) UIViewController* parent;
@property (copy, nonatomic) UserBlock chatAction;
@property (weak, nonatomic) IBOutlet BalloonLabel *introduction;
@end

@implementation UserCell

-(void)setUser:(User *)user
{
    _user = user;
    
    CLLocationDirection heading = __heading([Engine where], user.where);
    [self.userView clear];
    self.nickname.text = user.nickname;
    self.desc.text = user.desc;
    self.userView.user = user;
    self.age.text = user.age;
    self.compass.heading = heading;
    self.distance.text = __distanceString([[Engine where] distanceInKilometersTo:user.where]);
    self.gender.text = user.genderCode;
    self.gender.backgroundColor = user.genderColor;
    self.introduction.text = user.introduction;
    self.ago.text = user.updatedAt.timeAgoSimple;
    [self setLikeStatus:[[User me] likes:user]];
}

- (void)setLikeStatus:(BOOL) likes
{
    if (likes) {
        self.like.text = @"UNLIKE";
        self.like.backgroundColor = [UIColor colorWithRed:240/255.f green:82/255.f blue:10/255.f alpha:1.0f];

    }
    else {
        self.like.text = @"LIKE";
        self.like.backgroundColor = [UIColor colorWithRed:0/255.f green:150/255.f blue:0/255.f alpha:1.0f];
    }
}

- (IBAction)doChat:(id)sender {
    if (self.chatAction) {
        self.chatAction(self.user);
    }
}

- (IBAction)doLike:(id)sender {
    BOOL likes = [[User me] likes:self.user];
    if (likes) {
        [[User me] unlike:self.user];
    }
    else {
        [[User me] like:self.user];
    }
    [self setLikeStatus:!likes];
}

- (void)clicked
{
    [self.layer removeAllAnimations];
    [self.layer addAnimation:[self photoAnimations] forKey:nil];
}

- (CABasicAnimation*) photoAnimations
{
    const CGFloat sf = 1.02;
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    scale.toValue = [NSValue valueWithCGSize:CGSizeMake(sf, sf)];
    scale.duration = 0.1f;
    scale.autoreverses = YES;
    scale.repeatCount = 1;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scale.removedOnCompletion = YES;
    
    return scale;
}
@end

@interface Nearby ()
@property (strong, nonatomic) NSArray <User*> *users;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) Refresh *refresh;
@property (nonatomic) NSUInteger skip, limit;
@property (nonatomic) SegmentType segmentIndex;
@property (nonatomic) NearBySortBy sortby;
@property (weak, nonatomic) IBOutlet UILabel *sortbyLabel;
@end

@implementation Nearby

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.sortby = kNearBySortByLocation;
    self.segmentIndex = 0;
    self.skip = 0;
    self.limit = 200;
    self.refresh = [Refresh initWithCompletionBlock:^(UIRefreshControl *refreshControl) {
        [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    }];
    [self.tableView addSubview:self.refresh];
}

- (IBAction)segmentTapped:(UISegmentedControl*)sender {
    self.segmentIndex = sender.selectedSegmentIndex;
    self.skip = 0;
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
}

- (void)reloadAllUsersOnCondition:(NSUInteger)index reset:(BOOL)reset
{
    self.selectedRow = -1;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    if (![self.refresh isRefreshing]) {
        [self.refresh beginRefreshing];
    }
    if (reset) {
        self.skip = 0;
        self.users = nil;
        [self.tableView reloadData];
    }
    [self usersNear:[User me] completionHandler:^(NSArray<User *> *users) {
        if (reset) {
            self.users = users;
        }
        else {
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.users];
            [array addObjectsFromArray:users];
            self.users = array;
        }
        [self.refresh endRefreshing];
        [self.tableView reloadData];
    } condition:index];
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

- (void)usersNear:(User*)user completionHandler:(ArrayBlock)block condition:(NSUInteger)condition
{
    __LF
    PFQuery *query = [User query];
    [query setSkip:self.skip];
    [query setLimit:self.limit];
    [query includeKey:@"media"];
    
    //  No need to include keys... lazy loading when tapped.
    //  [query includeKey:@"photos"];
    
    switch (condition) {
        case kSegmentGirls:
            [query whereKey:@"gender" equalTo:@(kGenderTypeFemale)];
            break;
        case kSegmentBoys:
            [query whereKey:@"gender" equalTo:@(kGenderTypeMale)];
            break;
        case kSegmentAll:
            break;
        case kSegmentLikes:
            [query whereKey:@"objectId" containedIn:[self arrayOfUserIds:[User me].likes]];
            break;
        default:
            break;
    }
    [query whereKey:@"objectId" notEqualTo:[User me].objectId];
    if (self.sortby == kNearBySortByLocation) {
        NSLog(@"Querying location");
        [query whereKey:@"where" nearGeoPoint:[User me].where];
    }
    else {
        NSLog(@"Querying by time");
        [query orderByDescending:@"updatedAt"];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users, NSError * _Nullable error) {
        if (block) {
            block(users);
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
    ANOTIF(kNotificationSystemInitialized, @selector(systemInitialized:));
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
        UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
        
        __weak typeof(UserCell*) weakCell = cell;
        
        User *user = [self.users objectAtIndex:indexPath.row];
        
        cell.parent = self;
        cell.user = user;
        cell.chatAction = ^(User *user) {
            // actions
            [User payForChatWithUser:user onViewController:self action:^(id object) {
                if ([object isKindOfClass:[Channel class]]) {
                    NSLog(@"CHANNEL:%@", object);
                    [self performSegueWithIdentifier:@"Chat" sender:object];
                    weakCell.badgeValue = nil;
                }
                else if ([object isKindOfClass:[NSString class]]) {
                    NSLog(@"FIRST MESSAGE:%@", object);
                    [MessageCenter send:object users:@[user] completion:^(Channel *channel) {
                        [self performSegueWithIdentifier:@"Chat" sender:channel];
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
        NoMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMore" forIndexPath:indexPath];
        
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
        chat.channel = sender;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionUsers) {
        if (indexPath.row == self.selectedRow) {
            return 120;
        }
        else {
            return 65;
        }
    }
    else {
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
            
            [cell clicked];
        }
        else {
            prevCell.selected = NO;
            prevCell = cell;
            self.selectedRow = indexPath.row;
            cell.selected = YES;

            [cell clicked];
        }
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    else {
        self.skip += self.limit;
        [self reloadAllUsersOnCondition:self.segmentIndex reset:NO];
    }
}

- (IBAction)sortByTimeLocation:(UISwitch*)sender {
    __LF
    
    self.sortby = !sender.on;
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
    self.sortbyLabel.text = self.sortby ? @"By\nTime" : @"By\nGPS";
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
