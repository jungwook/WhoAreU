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
#import "MessageCenter.h"
#import "S3File.h"

#pragma mark ChatsCell

@interface ChatsCell : UITableViewCell
@property (strong, nonatomic) id dictionary;
@property (weak, nonatomic) IBOutlet UIView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nicknames;
@property (weak, nonatomic) IBOutlet UIView *badge;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@end

@implementation ChatsCell

- (void)setDictionary:(id)dictionary
{
    _dictionary = dictionary;

    id channelId = self.dictionary[fObjectId];
    NSArray *users = self.dictionary[fUsers];
    
    NSString *selectedThumbnail;
    for (id user in users) {
        id userId = user[fObjectId];
        id thumbnail = user[fThumbnail];
        
        if (![User meEquals:userId] && thumbnail) {
            selectedThumbnail = thumbnail;
        }
    }
    
    self.nicknames.text = [MessageCenter channelNameForChannelId:channelId];
    
    if (selectedThumbnail) {
        [S3File getImageFromFile:selectedThumbnail imageBlock:^(UIImage *image) {
            __drawImage(image, self.photoView);
        }];
    }
    else {
        __drawImage([UIImage imageNamed:@"avatar"], self.photoView);
    }
    
    id last = [[MessageCenter sortedMessagesForChannelId:channelId] lastObject];
    self.lastMessage.text = last[fMessage];
    self.badge.badgeValue = @([MessageCenter countUnreadMessagesForChannelId:channelId]).stringValue;
}

@end

#pragma mark Chats

@interface Chats ()
@property (nonatomic, weak) NSArray *chats;
@end

@implementation Chats

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ANOTIF(kNotificationNewChannelAdded, @selector(notificationNewChannelAdded:));
    ANOTIF(kNotificationNewChatMessage, @selector(notificationNewChatMessage:));
}

- (void) notificationNewChannelAdded:(id)notification
{
    __LF
    [self.tableView reloadData];
}

- (void) notificationNewChatMessage:(id)notification
{
    __LF
    [self.tableView reloadData];
}

- (NSArray *)chats
{
    return [MessageCenter liveChannels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    id dictionary = [self.chats objectAtIndex:indexPath.row];
    cell.dictionary = dictionary;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    __LF
    id dictionary = [self.chats objectAtIndex:indexPath.row];    
    [self performSegueWithIdentifier:@"Chat" sender:dictionary];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    __LF
    if ([segue.identifier isEqualToString:@"Chat"]) {
        Chat *chat = segue.destinationViewController;
        chat.hidesBottomBarWhenPushed = YES;
        chat.dictionary = sender;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        __alert(@"Are you sure?", @"All contents will be permanently deleted.", ^(UIAlertAction* action) {
            id dictionary = [self.chats objectAtIndex:indexPath.row];
            id channelId = dictionary[fObjectId];
            [MessageCenter removeChannelMessages:channelId];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [tableView reloadData];
                [MessageCenter setSystemBadge];
            });
        }, ^(UIAlertAction* action) {
        }, self);
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
