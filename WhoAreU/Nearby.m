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
@property (weak, nonatomic) IBOutlet MediaCollection *mediaCollection;
@property (weak, nonatomic) UIViewController* parent;
@property (copy, nonatomic) UserBlock chatAction;
@property (copy, nonatomic) UserBlock profileAction;
@property (weak, nonatomic) IBOutlet BalloonLabel *introduction;
@property (nonatomic) BOOL expand;
@end

@implementation UserCell

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
//    self.backgroundColor = selected ? [UIColor groupTableViewBackgroundColor] : [UIColor clearColor];
}

-(void)setUser:(User *)user
{
    _user = user;

    CLLocationDirection heading = __heading([Engine where], user.where);
    [self.userView clear];
    self.nickname.text = user.nickname;
    self.desc.text = user.desc;
    self.userView.parent = self.parent;
    self.userView.user = user;
    self.age.text = user.age;
    self.compass.heading = heading;
    self.distance.text = __distanceString([[Engine where] distanceInKilometersTo:user.where]);
    self.gender.text = user.genderCode;
    self.gender.backgroundColor = user.genderColor;
    self.mediaCollection.parent = self.parent;
    self.introduction.text = user.introduction;
    self.introduction.hidden = (user.introduction == nil);
    self.ago.text = user.whereUdatedAt.timeAgoSimple;
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

- (IBAction)doProfile:(id)sender {
    if (self.profileAction) {
        self.profileAction(self.user);
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

- (void)setExpand:(BOOL)expand
{
    _expand = expand;
    
    if (self.expand) {
        self.mediaCollection.user = self.user;
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.mediaCollection.user = nil;
        });
    }
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
@end

@implementation Nearby

- (void)awakeFromNib
{
    [super awakeFromNib];
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
        self.users = [self sortUsersByDistance:self.users];
        
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
    [query whereKey:@"where" nearGeoPoint:[User me].where];
    [query orderByAscending:@"where"];
    [query whereKey:@"objectId" notEqualTo:[User me].objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users, NSError * _Nullable error) {
        if (block) {
            block(users);
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedRow = -1;
    [self reloadAllUsersOnCondition:self.segmentIndex reset:YES];
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
            [Installation payForChatWithUser:user onViewController:self action:^(NSString* message) {
                NSString *textToSend = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                [Engine send:textToSend toUser:user completion:^{
                    [self performSegueWithIdentifier:@"Chat" sender:user];
                    weakCell.userView.badgeValue = nil;
                }];
            }];
        };
        
        cell.profileAction = ^(User *user) {
            [self performSegueWithIdentifier:@"UserProfile" sender:user];
        };
        if (indexPath.row == self.selectedRow) {
            cell.expand = YES;
            cell.mediaCollection.user = user;
        }
        else {
            cell.mediaCollection.user = nil;
        }
        
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
        chat.user = sender;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionUsers) {
        if (indexPath.row == self.selectedRow) {
            return 220;
        }
        else {
            return 70;
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
            cell.expand = NO;
        }
        else {
            prevCell.selected = NO;
            prevCell = cell;
            self.selectedRow = indexPath.row;
            cell.selected = YES;
            cell.expand = YES;
        }
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    else {
        self.skip += self.limit;
        [self reloadAllUsersOnCondition:self.segmentIndex reset:NO];
    }
}

- (IBAction)testSendChannel:(id)sender {
    [Engine sendChannelMessage:@"Testing 123..."];
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
