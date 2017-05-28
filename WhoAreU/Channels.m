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
#import "PopupMenu.h"
#import "DropDownNavigationItem.h"

#define CHATMAXWIDTH 270
#define MEDIASIZE 160

#define INSET 8
#define chatFont [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
#define systemFont [UIFont systemFontOfSize:12]
#define boldSystemFont [UIFont boldSystemFontOfSize:12]

NSAttributedString* nicknameWithSystemMessage(id nickname, id message)
{
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:nickname ? nickname : @"UNKNOWN" attributes:@{                                                                                                                   NSFontAttributeName : boldSystemFont,}];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", message] attributes:@{NSFontAttributeName : systemFont,}]];
    return attr;
}

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
    
    self.systemLog.attributedText = nicknameWithSystemMessage(nickname, msg);
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
@property (weak, nonatomic) IBOutlet BalloonLabel *introduction;
@end

@implementation SystemRow

- (void)setInfo:(id)info
{
    _info = info;
    
    id me = info[fMe];
    id nickname = me[fNickname];
    id userId = me[fObjectId];
    id thumbnail = me[fThumbnail];
    id introduction = me[fIntroduction];
    id gender = me[fGender];
    id genderColor = [User genderColorFromTypeString:gender];
    
    NSDate *when = [NSDate dateFromStringUTC:info[fWhen]];
    NSString *msg = info[fMessage];

    self.systemLog.attributedText = nicknameWithSystemMessage(nickname, msg);
    self.when.text = [NSString stringWithFormat:@"%@ ago", when.timeAgoSimple];
    self.introduction.text = introduction ? introduction : @"Hi";
    self.introduction.backgroundColor = genderColor;
    self.introduction.font = chatFont;
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
Channel Message:{
    channel = "Let's meet";
    channelType = message;
    distance = 0;
    me =     {
        age = 20s;
        channel = "Let's meet";
        gender = Female;
        introduction = "\Uc548\Ub155\Ud558\Uc138\Uc694! \Uc560\Uc778 \Ucc3e\Uc544\Uc694.";
        latitude = "37.51579284667969";
        longitude = "127.0278091430664";
        nickname = wahtever;
        objectId = 0O42fMfR0i;
        thumbnail = "ProfileMedia/0O42fMfR0i/3GVUSH9S.jpg";
    };
    message = "Hello it's me";
    senderId = 0O42fMfR0i;
    type = 1; // MessageType
    when = "2017-05-28T04:01:24.208Z";
    where =     {
        latitude = "37.51579284667969";
        longitude = "127.0278091430664";
    };
}
*/

@implementation ChannelRow

- (void)setMessage:(id)message
{
    _message = message;
    
    id me = message[fMe];
    
    NSDate *when = [NSDate dateFromStringUTC:message[fWhen]];
    PFGeoPoint *where = [PFGeoPoint geoPointFromWhere:message[fWhere]];
    CGFloat distance = [[User where] distanceInKilometersTo:where];
    CGFloat heading = [[User where] headingToLocation:where];
    id introduction = message[fMessage];
    id media = message[fMedia];
    id mediaFile = media[fMedia];
    id thumbnail = me[fThumbnail];
    id userId = me[fObjectId];
    id nickname = me[fNickname];
    id gender = me[fGender];
    id genderColor = [User genderColorFromTypeString:gender];
    
    self.nickname.text = nickname;
    self.distance.text = __distanceString(distance);
    self.compass.heading = heading;

    [self.userView setUserId:userId withThumbnail:thumbnail];
    
    self.introduction.backgroundColor = genderColor;
    self.introduction.text = introduction;
    self.introduction.font = chatFont;

    self.when.text = [NSString stringWithFormat:@"%@ ago", when.timeAgoSimple];

    if (media && media[fMedia]) {
        self.introduction.mediaFile = mediaFile;
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
    id menu = @[
                @{ fTitle : @"Select a Channel",
                   fItems : [User channels],
                   },
                ];

    [super awakeFromNib];
    
    DropDownNavigationItem *navItem = (DropDownNavigationItem*) self.navigationItem;
    
    navItem.menuItems = menu;
    IndexBlock action = ^(NSUInteger section, NSUInteger index) {
        id channel = menu[section][fItems][index];
        [navItem setTitle:channel];
        [User setChannel:channel];
    };
    navItem.action = action;
    
    self.filePath = FileURL(@"channelMessagesFile");    
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
}

- (void) notificationUserLoggedIn:(id)sender
{
    self.navigationItem.title = [User me].channel;
}

-(void) onNavButtonTapped:(UIBarButtonItem *)sender event:(UIEvent *)event
{

    id menu = @[
                @{ fTitle : @"message",
                   fItems : @[
                           @"I'm lonely tonight",
                           @"Let's meet",
                           @"How about dinner?",
                           @"Anyone interested in a movie?",
                           @"Drive away with me",
                           ],
                   fIcons : @[
                           @"message2",
                           @"camera",
                           @"message2",
                           @"camera",
                           @"message2",
                           ],
                   },
                @{ fTitle : @"photo or video",
                   fItems : @[
                           @"Send a photo",
                           ],
                   fIcons : @[
                           @"message2",
                           ],
                   },
                @{ fTitle : @"Custom message",
                   fItems : @[
                           @"Your message",
                           ],
                   },
                @{ fTitle : @"A Section",
                   },
                ];
    
    [PopupMenu showFromView:sender
                  menuItems:menu
                 completion:^(NSUInteger section, NSUInteger index)
    {
        id message = menu[section][@"items"][index];
        
        [MessageCenter sendMessageToNearbyUsers:message];
    } cancel:^{
        NSLog(@"Cancelled");
    }];
    
    return;
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
        return 56.0f;
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
                return [messageString heightWithFont:chatFont maxWidth:CHATMAXWIDTH-3*INSET]+room*INSET;
            }
        }
    }
}

@end
