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

@interface UserCell : UITableViewCell
@property (weak, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *desc;
@property (weak, nonatomic) IBOutlet IndentedLabel *age;
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@property (weak, nonatomic) IBOutlet Compass *compass;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *userId;
@property (weak, nonatomic) UIViewController* parent;
@property (nonatomic) CGFloat heading;
@property (copy, nonatomic) UserBlock doChatBlock;
@end

@implementation UserCell

-(void)setUser:(User *)user
{
    _user = user;
    
    [self.photoView clear];
    self.nickname.text = user.nickname;
    self.desc.text = user.desc;
    self.photoView.parent = self.parent;
    self.photoView.media = user.media;
    self.age.text = user.age;
    self.userId.text = user.objectId;
    self.compass.heading = __heading([Engine where], user.where);
    self.heading = self.compass.heading;
    self.distance.text = __distanceString([[Engine where] distanceInKilometersTo:user.where]);    
}

- (IBAction)doChat:(id)sender {
    __LF
    if (self.doChatBlock) {
        self.doChatBlock(self.user);
    }
}

@end

@interface Nearby ()
@property (strong, nonatomic) NSArray <User*> *users;
@end

@implementation Nearby

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self reloadUsers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void) reloadUsers
{
    PFQuery *query = [User query];
    [query whereKeyDoesNotExist:@"simulated"];
    [query whereKey:@"objectId" notEqualTo:[User me].objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        self.users = objects;
        [self.tableView reloadData];
        NSLog(@"Loaded %ld users", self.users.count);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];

    cell.parent = self;
    cell.user = [self.users objectAtIndex:indexPath.row];
    cell.doChatBlock = ^(User *user) {
        // actions
        [Installation payForChatOnViewController:self action:^{
            [self performSegueWithIdentifier:@"Chat" sender:user];
        }];
    };
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"UserProfile"]) {
        UserCell *cell = sender;
        UserProfile *vc = segue.destinationViewController;
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        vc.user = cell.user;
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
    return 60;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
