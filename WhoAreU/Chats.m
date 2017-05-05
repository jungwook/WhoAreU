//
//  Chats.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chats.h"
#import "PhotoView.h"
#import "IndentedLabel.h"
#import "Compass.h"
#import "Chat.h"

#pragma mark ChatsCell

@interface ChatsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UserView *userView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@property (weak, nonatomic) IBOutlet IndentedLabel *age;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet Compass *compass;
@property (weak, nonatomic) UIViewController *parent;
@property (weak, nonatomic) id userId;
@property (strong, nonatomic) User* user;
@end

@implementation ChatsCell

-(void)setUser:(User *)user
{
    _user = user;
    
    self.userView.user = user;
    self.nickname.text = user.nickname;
    self.introduction.text = user.desc;
    self.age.text = user.age;
    self.distance.text = __distanceString([[Engine where] distanceInKilometersTo:user.where]);
    self.compass.heading = __headingUsers(self.user, [User me]);
}

- (void)setParent:(UIViewController *)parent
{
    self.userView.parent = parent;
}

- (void) setUserId:(id)userId
{
    User *user = [User objectWithoutDataWithObjectId:userId];
    [user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        self.user = user;
    }];
}

@end

#pragma mark Chats

@interface Chats ()
@property (nonatomic, weak) NSArray *chats;
@end

@implementation Chats

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (NSArray *)chats
{
    return [Engine chatUserIds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Chat"]) {
        ChatsCell *cell = sender;
        Chat *chat = segue.destinationViewController;
        chat.hidesBottomBarWhenPushed = YES;
        chat.user = cell.user;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    id userId = [self.chats objectAtIndex:indexPath.row];
    [cell setUserId:userId];
    [cell setParent:self];
    
    return cell;
}

- (void)viewWillAppear:(BOOL)animated
{
    __LF
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    __LF
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        __alert(self, @"Are you sure?", @"All contents will be permanently deleted.", ^(UIAlertAction* action) {
            id userId = [self.chats objectAtIndex:indexPath.row];
            [Engine deleteChatWithUserId:userId];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }, ^(UIAlertAction* action) {
            
        });
    }
}

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
