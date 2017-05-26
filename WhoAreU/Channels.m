//
//  Channel.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 8..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Channels.h"
#import "PhotoView.h"
#import "IndentedLabel.h"
#import "BalloonLabel.h"
#import "Compass.h"
#import "S3File.h"
#import "Refresh.h"
#import "MessageCenter.h"
#import "PopOverMenu.h"

#define CHATMAXWIDTH 200
#define MEDIASIZE 160

#define INSET 8
#define chatFont [UIFont systemFontOfSize:14]

@interface SetupRow : UITableViewCell
@property (strong, nonatomic) id info;
@property (weak, nonatomic) IBOutlet UILabel *systemLog;
@property (weak, nonatomic) IBOutlet UserView *userView;
@property (weak, nonatomic) IBOutlet UILabel *when;
@property (weak, nonatomic) IBOutlet UIView *setupView;
@end

@implementation SetupRow

- (void)setInfo:(id)info
{
    _info = info;
    
    id me = info[fMe];
    id nickname = me[fNickname];
    id when = info[fWhen];
    id userId = me[fObjectId];
    id thumbnail = me[fThumbnail];
    
    NSDate *date = [NSDate dateFromStringUTC:when];
    NSString *msg = info[fMessage];
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:nickname ? nickname : @"UNKNOWN" attributes:@{                                                                                                                   NSFontAttributeName : [UIFont boldSystemFontOfSize:14],}];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", msg] attributes:@{NSFontAttributeName : chatFont,}]];
    
    self.systemLog.attributedText = attr;
    self.when.text = date.timeAgo;
    self.setupView.backgroundColor = [User me].genderColor;
    [self.userView setUserId:userId withThumbnail:thumbnail];
}
@end

@interface SystemRow : UITableViewCell
@property (nonatomic, strong) id info;
@property (weak, nonatomic) IBOutlet UILabel *systemLog;
@property (weak, nonatomic) IBOutlet UserView *userView;
@property (weak, nonatomic) IBOutlet UILabel *when;
@end

@implementation SystemRow

- (void)setInfo:(id)info
{
    _info = info;
    
    id me = info[fMe];
    id nickname = me[fNickname];
    id when = info[fWhen];
    id userId = me[fObjectId];
    id thumbnail = me[fThumbnail];
    
    
    NSDate *date = [NSDate dateFromStringUTC:when];
    NSString *msg = info[fMessage];
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:nickname ? nickname : @"UNKNOWN" attributes:@{                                                                                                                   NSFontAttributeName : [UIFont boldSystemFontOfSize:14],}];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", msg] attributes:@{NSFontAttributeName : chatFont,}]];

    self.systemLog.attributedText = attr;
    self.when.text = date.timeAgo;
    [self.userView setUserId:userId withThumbnail:thumbnail];
}

@end

@interface ChannelRow : UITableViewCell
@property (strong, nonatomic) id message;

@property (weak, nonatomic) IBOutlet UserView *userView;
@property (weak, nonatomic) IBOutlet BalloonLabel *introduction;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *when;
@property (weak, nonatomic) IBOutlet Compass *compass;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@end

/*
object = {
    distance = 0;
    me =     {
        age = 20s;
        channel = Flirt;
        gender = Male;
        introduction = "i am such a hunk";
        latitude = "37.5060899262235";
        longitude = "127.063861573541";
        nickname = iphone;
        objectId = GFjHKP0CsY;
        thumbnail = "ProfileMedia/GFjHKP0CsY/JtIFZTzI.jpg";
    };
    message = "iphone logged in.";
    senderId = GFjHKP0CsY;
    when = "2017-05-24T02:24:02.035Z";
    where =     {
        latitude = "37.5060899262235";
        longitude = "127.063861573541";
    };
}}
 */
@implementation ChannelRow

- (void)setMessage:(id)message
{
    _message = message;
    
    id distance = message[fDistance];
    id me = message[fMe];
    
    NSDate *date = [NSDate dateFromStringUTC:message[fWhen]];
    
    PFGeoPoint *where = [PFGeoPoint geoPointWithLatitude:[message[fLatitude] floatValue] longitude:[message[fLongitude] floatValue]];
    self.nickname.text = me[fNickname];
    self.distance.text = __distanceString([distance floatValue]);
    self.compass.heading = [[User me].where headingToLocation:where];
    self.introduction.backgroundColor = [User genderColorFromTypeString:me[fGender]];

    id thumbnail = me[fThumbnail];
    id userId = me[fObjectId];
    [self.userView setUserId:userId withThumbnail:thumbnail];
    
    self.introduction.text = message[fMessage];
    self.when.text = date.timeAgoSimple;
    id media = message[fMedia];
    
    if (media && media[fMedia]) {
        self.introduction.mediaFile = media[fMedia];
    }
    else {
        self.introduction.mediaFile = nil;
    }
}

@end

@interface Channels ()
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) Refresh *refresh;
@property (strong, nonatomic) NSURL *filePath;
@end

@implementation Channels

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.filePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"channelMessagesFile"];
    
    self.messages = [NSMutableArray arrayWithContentsOfURL:self.filePath];
    if (!self.messages) {
        self.messages = [NSMutableArray new];
    }

    self.refresh = [Refresh initWithCompletionBlock:^(UIRefreshControl *refreshControl) {
        [self.tableView reloadData];
        if ([self.refresh isRefreshing])
            [self.refresh endRefreshing];
    }];
    [self.tableView addSubview:self.refresh];
    
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"message2"] style:UIBarButtonItemStyleDone target:self action:@selector(onNavButtonTapped:event:)];
    [bbi setTintColor:[UIColor blackColor]];
    
    [self.navigationItem setRightBarButtonItem:bbi];
    
    ANOTIF(kNotificationChannelMessage, @selector(newChannelMessage:));
    ANOTIF(kNotificationUserLoggedInMessage, @selector(notificationUserLoggedIn:));
    
    
    PopOverMenuConfiguration *configuration = [PopOverMenuConfiguration defaultConfiguration];
//    configuration.menuRowHeight = ...
    configuration.menuWidth = 200.0f;
    configuration.textColor = [UIColor darkGrayColor];
//    configuration.textFont = ...
    configuration.tintColor = [UIColor whiteColor];
    configuration.borderColor = [UIColor whiteColor];
//    configuration.borderWidth = ...
    configuration.textAlignment = NSTextAlignmentLeft;
    configuration.ignoreImageOriginalColor = YES; // set 'ignoreImageOriginalColor' to YES, images color will be same as textColor
    configuration.allowRoundedArrow = NO; // Default is 'NO', if sets to 'YES', the arrow will be drawn with round corner.
}

- (void) notificationUserLoggedIn:(id)sender
{
    self.navigationItem.title = [User me].channel;
}

-(void)onNavButtonTapped:(UIBarButtonItem *)sender event:(UIEvent *)event
{
    id menu = @[
                @"I'm lonely tonight",
                @"Let's meet",
                @"How about dinner?",
                @"Anyone interested in a movie?",
                @"Drive away with me",
                ];
    id images = @[
                  @"message2",
                  @"camera",
                  @"message2",
                  @"camera",
                  @"message2",
                  ];
    
    [PopOverMenu showFromEvent:event
                   withMenuArray:menu
                      imageArray:images
                       doneBlock:^(NSInteger selectedIndex)
    {
        id message = menu[selectedIndex];
        id packet = @{
                      fOperation    : @"pushHiToUsersNearMe",
                      fWhen         : [NSDate date].stringUTC,
                      fMessage      : message,
                      fChannelType : @"message",
                      fType : @(kMessageTypeText),
                      fMedia : @{},
                      };
        [MessageCenter send:packet];
    } dismissBlock:^{
        
    }];
}

- (IBAction)sendChannelMessage:(id)sender {
    [User payForChatWithChannelOnViewController:self action:^(id ret) {
        id message = ret[fMessage];
        id type = ret[fType];
        id media = ret[fMedia] ? ret[fMedia] : @{};
        id packet = @{
                      fOperation    : @"pushHiToUsersNearMe",
                      fWhen         : [NSDate date].stringUTC,
                      fMessage      : message,
                      fChannelType : @"message",
                      fType : type,
                      fMedia : media,
                      };
        
        [MessageCenter send:packet];
    }];
}

- (void) addMessageToMessages:(id)message
{
    [self.messages insertObject:message atIndex:0];
    BOOL ret = [self.messages writeToURL:self.filePath atomically:YES];
    if (!ret) {
        NSLog(@"ERROR SAVING TO %@", self.filePath);
    }
    else {
        NSLog(@"SAVED TO %@", self.filePath);
    }
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    [self.tableView reloadData];
}

- (void)newChannelMessage:(NSNotification*)notification
{
    __LF
    NSLog(@"Channel Message:%@", notification.object);
    [self addMessageToMessages:notification.object];
}

- (void) dealloc
{
    __LF

    RANOTIF;
}

- (void)viewWillAppear:(BOOL)animated
{
    __LF
    self.navigationItem.title = [User me].channel;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    id message = [self.messages objectAtIndex:indexPath.row];
    
    id channelType = message[fChannelType];
    if ([channelType isEqualToString:@"system"]) {
        SystemRow *cell = [tableView dequeueReusableCellWithIdentifier:@"SystemRow" forIndexPath:indexPath];
        
        cell.info = message;
        return cell;
    }
    else if ([channelType isEqualToString:@"setup"]) {
        SetupRow *cell = [tableView dequeueReusableCellWithIdentifier:@"SetupRow" forIndexPath:indexPath];
        
        cell.info = message;
        return cell;
    }
    else {
        ChannelRow *cell = [tableView dequeueReusableCellWithIdentifier:@"ChannelRow" forIndexPath:indexPath];
        
        cell.message = message;
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id message = [self.messages objectAtIndex:indexPath.row];
    
    id channelType = message[fChannelType];
    if ([channelType isEqualToString:@"system"]) {
        return 30.0f;
    }
    else if ([channelType isEqualToString:@"setup"]) {
        return 30.0f;
    }
    else {
        MessageType type = [[message objectForKey:fType] integerValue];
        
        CGFloat room = 4.75;
        switch (type) {
            case kMessageTypeMedia: {
                id media = [message objectForKey:fMedia];
                CGSize size = CGSizeFromString([media objectForKey:fSize]);
                CGFloat h = MEDIASIZE * size.height / size.width;
                return h+room*INSET;
            }
            default:
            case kMessageTypeText: {
                id messageString = message[fMessage];
                return [messageString heightWithFont:chatFont maxWidth:CHATMAXWIDTH+2*INSET+10]+room*INSET;
            }
        }
    }
}

@end
