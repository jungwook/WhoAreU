//
//  Channel.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 8..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Channel.h"
#import "PhotoView.h"
#import "IndentedLabel.h"
#import "BalloonLabel.h"
#import "Compass.h"
#import "S3File.h"
#import "Refresh.h"

@interface ChannelRow : UITableViewCell
@property (strong, nonatomic) id userInfo;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) id userId;

@property (weak, nonatomic) UIViewController* parent;
@property (weak, nonatomic) IBOutlet UIView *userView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *desc;
@property (weak, nonatomic) IBOutlet BalloonLabel *introduction;
@property (weak, nonatomic) IBOutlet IndentedLabel *age;
@property (weak, nonatomic) IBOutlet IndentedLabel *gender;
@property (weak, nonatomic) IBOutlet IndentedLabel *ago;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet Compass *compass;
@end

@implementation ChannelRow

- (void)setUserInfo:(id)userInfo
{
    _userInfo = userInfo;
    NSDate *updatedAt = userInfo[@"updatedAt"];
    id payload = userInfo[@"payload"];
    
    self.userId = payload[@"senderId"];
    id whereDic = payload[@"where"];
    
    NSNumber *latitude = whereDic[@"latitude"];
    NSNumber *longitude = whereDic[@"longitude"];
    
    id thumbnail = payload[@"thumbnail"];
    [S3File getImageFromFile:thumbnail imageBlock:^(UIImage *image) {
        __drawImage(image, self.userView);
    }];

    PFGeoPoint *where = [PFGeoPoint geoPointWithLatitude:latitude.floatValue longitude:longitude.floatValue];
    CGFloat distance = [where distanceInKilometersTo:[User me].where];
    CLLocationDirection heading = __heading(where, [User me].where);
    
    self.nickname.text = payload[@"nickname"];
    self.desc.text = payload[@"desc"];
    self.introduction.text = payload[@"message"];
    self.age.text = payload[@"age"];
    self.gender.text = payload[@"gender"];
    self.gender.backgroundColor = UIColorFromNSString(payload[@"genderColor"]);
    self.distance.text = __distanceString(distance);
    self.compass.heading = heading;
    self.ago.text = updatedAt.timeAgoSimple;
    
    NSLog(@"D:%f [%@/%@ - %@] ", distance, where, [User me].where, [Engine where]);
}

- (void)setParent:(UIViewController *)parent
{
//    self.userView.parent = parent;
}

@end

@interface Channel ()
@property (strong, nonatomic) Queue *messages;
@property (strong, nonatomic) Refresh *refresh;
@end

@implementation Channel

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messages = [Queue new];
    self.refresh = [Refresh initWithCompletionBlock:^(UIRefreshControl *refreshControl) {
        [self.tableView reloadData];
        if ([self.refresh isRefreshing])
            [self.refresh endRefreshing];
    }];
    [self.tableView addSubview:self.refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newChannelMessage:)
                                                 name:kNotificationNewChannelMessage
                                               object:nil];
    
}

- (IBAction)sendChannelMessage:(id)sender {
    [Engine sendChannelMessage:@"Testing 123..."];
}

- (void)newChannelMessage:(id)sender
{
    __LF
    NSLog(@"Channel Message:%@", sender);
    [self.tableView reloadData];
}

- (void) dealloc
{
    __LF
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationNewChannelMessage object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView reloadData];
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
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id userInfo = [self.messages objectAtIndex:indexPath.row];
    
    ChannelRow *cell = [tableView dequeueReusableCellWithIdentifier:@"ChannelRow" forIndexPath:indexPath];
    
    cell.parent = self;
    cell.userInfo = userInfo;
    
    return cell;
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
