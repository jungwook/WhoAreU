//
//  Profile.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Profile.h"
#import "ProfileCell.h"
#import "UserMapCell.h"
#import "FollowCell.h"
#import "CommentCell.h"
#import "AddCommentCell.h"
#import "MessageCenter.h"
#import "Chat.h"
#import "PopupMenu.h"

@interface Profile ()
@property (strong, nonatomic) NSArray<User*> *following;
@property (strong, nonatomic) NSMutableArray<Comment*> *comments;
@property (nonatomic) NSUInteger commentsLimit;
@property (nonatomic) NSUInteger commentsSkip;
@end

@implementation Profile

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.commentsLimit = 20;
    self.comments = [NSMutableArray array];
}

- (void)setUser:(User *)user
{
    _user = user;
    [[self.user fetchIfNeededInBackground] continueWithSuccessBlock:^id _Nullable(BFTask<__kindof PFObject *> * _Nonnull task) {
        self.navigationItem.title = self.user.nickname;
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:kProfileCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kProfileCell];
    [self.tableView registerNib:[UINib nibWithNibName:kUserMapCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kUserMapCell];
    [self.tableView registerNib:[UINib nibWithNibName:kFollowCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kFollowCell];
    [self.tableView registerNib:[UINib nibWithNibName:kCommentCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kCommentCell];
    [self.tableView registerNib:[UINib nibWithNibName:kAddCommentCell bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kAddCommentCell];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"message2"] style:UIBarButtonItemStylePlain target:self action:@selector(chatWithUserFromBBI:)]];
    
    Notification(UIKeyboardWillShowNotification, keyboardWillShow:);
    Notification(UIKeyboardWillHideNotification, keyboardWillHide:);
    
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)]];
}

- (void) tappedOutside:(id)sender
{
    [self.tableView endEditing:YES];
}

- (void) keyboardWillShow:(NSNotification*)notification
{
    CGRect rect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat h = CGRectGetHeight(rect);
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, h, 0);
    [self scrollToBottom];
}

- (void) scrollToBottom
{
    NSUInteger section = 1;
    NSUInteger rows = self.comments.count;
    NSIndexPath *last = [NSIndexPath indexPathForRow:rows inSection:section];
    [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void) keyboardWillHide:(id)sender
{
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
}


- (void)viewWillAppear:(BOOL)animated
{
    __LF
    [self loadFollowers];
    [self loadComments];
}

- (void) loadComments
{
    PFQuery *query = [Comment query];
    [query whereKey:fOnId equalTo:self.user.objectId];
    [query whereKey:fType equalTo:@(CommentTypeUser)];
    [query orderByAscending:fCreatedAt];
    [query setSkip:self.commentsSkip];
    [query setLimit:self.commentsLimit];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        [self.comments addObjectsFromArray:objects];
        [self.tableView reloadData];
        self.commentsSkip += objects.count;
    }];
}

- (void) loadFollowers
{
    PFQuery *query = [User query];
    [query whereKey:fLikes containsAllObjectsInArray:@[self.user]];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        self.following = objects;
        [self.tableView reloadData];
    }];
}

- (void) chatWithUserFromBBI:(id)sender
{
    [self chatWithUser:self.user];
}

- (void) chatWithUser:(User*)user
{
    [User payForChatWithUser:user
            onViewController:self
                      action:^(id object) {
        if ([object isKindOfClass:[Channel class]]) {
            Channel *channel = object;
            [self performSegueWithIdentifier:kSegueIdentifierChat
                                      sender:channel.dictionary];
        }
        else if ([object isKindOfClass:[NSString class]]) {
            [MessageCenter send:object
                          users:@[user]
                     completion:^(Channel *channel)
            {
                [self performSegueWithIdentifier:kSegueIdentifierChat
                                          sender:channel.dictionary];
            }];
        }
        else {
            NSLog(@"ERROR[%s]:Unknown return", __func__);
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueIdentifierChat]) {
        // other preparations.
        Chat *chat = segue.destinationViewController;
        chat.hidesBottomBarWhenPushed = YES;
        chat.dictionary = sender;
    }
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
    
    switch ((ProfileSections)section) {
        case ProfileSectionProfile:
            return 4;
            
        case ProfileSectionComments:
        default:
            return self.comments.count+1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProfileRowType type = indexPath.row;
    ProfileSections section = indexPath.section;
    
    switch (section) {
        case ProfileSectionProfile:
            switch (type) {
                case RowTypeProfile: {
                    ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileCell forIndexPath:indexPath];
                    
                    cell.user = self.user;
                    cell.chatAction = ^{
                        [self chatWithUser:self.user];
                    };
                    return cell;
                }
                    break;
                case RowTypeFollowers:
                {
                    FollowCell *cell = [tableView dequeueReusableCellWithIdentifier:kFollowCell forIndexPath:indexPath];
                    cell.photoAction = self.photoAction;
                    cell.users = self.user.likes;
                    [cell setNickname:self.user.nickname type:FollowCellTypeFollows];
                    return cell;
                }
                    break;
                case RowTypeFollowing:
                {
                    FollowCell *cell = [tableView dequeueReusableCellWithIdentifier:kFollowCell forIndexPath:indexPath];
                    cell.photoAction = self.photoAction;
                    cell.users = self.following;
                    [cell setNickname:self.user.nickname type:FollowCellTypeFollowing];
                    return cell;
                }
                    break;
                case RowTypeMap:
                {
                    UserMapCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserMapCell forIndexPath:indexPath];
                    
                    cell.user = self.user;
                    cell.photoAction = self.photoAction;
                    return cell;
                }
                    break;
            }
            break;
        case ProfileSectionComments: {
            if (indexPath.row == self.comments.count) {
                AddCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:kAddCommentCell forIndexPath:indexPath];
                cell.user = self.user;
                cell.photoAction = self.photoAction;
                cell.saveAction = ^(id object) {
                    [self.comments addObject:object];
                    [self.tableView reloadData];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                };
                cell.loadMoreAction = ^{
                    [self.tableView reloadData];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                };
                return cell;
            }
            else {
                CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:kCommentCell forIndexPath:indexPath];
                Comment *comment = [self.comments objectAtIndex:indexPath.row];
                cell.comment = comment;
                cell.photoAction = self.photoAction;
                return cell;
            }
        }
    }
}

- (void (^)(User* user, UIView *view, CGRect rect))photoAction
{
    return ^(User *user, UIView *view, CGRect rect) {
        if (user) {
            BOOL isMe = [User meEquals:user.objectId];
            
            NSString *title = user.dataAvailable ? user.nickname : @"user";
            [PopupMenu showFromView:view
                          menuItems:@[
                                      @{
                                          fTitle : title,
                                          fItems : isMe ? @[ @"Profile"]
                                          : @[
                                              @"Profile",
                                              @"Chat",
                                              ],
                                          fIcons : isMe ? @[ @"user" ] : @[
                                                  @"user",
                                                  @"message2",
                                                  ],
                                          },
                                                     ]
                         completion:^(NSUInteger section, NSUInteger index) {
                             if (index == 1) {
                                 [self chatWithUser:user];
                             }
                             else if (index == 0) {
                                 Profile *profile = [self.storyboard instantiateViewControllerWithIdentifier:@"Profile"];
                                 profile.hidesBottomBarWhenPushed = YES;
                                 profile.user = user;
                                 
                                 [self.navigationController pushViewController:profile animated:YES];
                             }
                         }
                             cancel:nil
                               rect:rect];
        }
    };
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const CGFloat followingHeight = 100.0f;
    ProfileRowType type = indexPath.row;
    ProfileSections section = indexPath.section;
    CGFloat w = CGRectGetWidth(self.tableView.frame);
    
    switch (section) {
        case ProfileSectionProfile: {
            switch (type) {
                case RowTypeProfile: {
                    NSString *introduction = self.user.introduction;
                    CGFloat i = 8.0f;
                    CGFloat x = [ProfileCell introductionOffset].x;
                    CGFloat h = [introduction heightWithFont:[ProfileCell font] maxWidth:(w-x-i)];
                    return w+h+80.0f;
                }
                    
                case RowTypeFollowers:
                    return self.user.likes.count > 0 ? followingHeight : 0;
                    
                case RowTypeFollowing:
                    return self.following.count > 0 ? followingHeight : 0;
                    
                case RowTypeMap:
                    return 30.f+w/2.0f;
            }
        }
        case ProfileSectionComments: {
            if (indexPath.row == self.comments.count) {
                return 180.0f;
            }
            else {
                Comment *comment = [self.comments objectAtIndex:indexPath.row];
                CGFloat offset = 66.0f;
                CGFloat inset = 8.0f;
                CGFloat width = CGRectGetWidth(self.tableView.frame);
                CGFloat h = [comment.comment heightWithFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium] maxWidth:width-offset-inset];
                
                return offset + h + inset;
            }
        }
    }
}

@end


