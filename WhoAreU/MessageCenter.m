//
//  MessageCenter.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MessageCenter.h"
#import "S3File.h"
#import "NSData+GZIP.h"

@interface MessageCenter()
@property (strong, nonatomic) NSMutableDictionary *chats, *channelUsers;
@property (strong, nonatomic) NSURL *chatsFile, *channelsFile;
@property (strong, nonatomic) NSMutableDictionary *pushHandlers;
@end

@implementation MessageCenter

+ (instancetype) new
{
    static id sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[self alloc] initOnce];
    });
    return sharedFile;
}

- (instancetype)initOnce
{
    __LF
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

typedef UNNotificationPresentationOptions(^PushBlock)(id message);

- (void) setup
{
    [self loadFiles];
    [self setupPushHandlers];
    
}

- (void) setupPushHandlers
{
    self.pushHandlers = [NSMutableDictionary dictionary];
    
    PushBlock pushTypeChannel = ^(id userInfo) {
        return UNNotificationPresentationOptionNone;
    };
    PushBlock pushTypeMessage = ^(id userInfo) {
        return UNNotificationPresentationOptionSound;
    };
    PushBlock pushTypeChatChannel = ^(id userInfo) {
        MessageCenter *center = [MessageCenter new];
        id payload = userInfo[fPayload];
        id channelId = payload[fChannelId];
        
        if (![center.channelUsers objectForKey:channelId]) {
            [center addToSystemChannelId:channelId];
        }
        [MessageCenter processFetchedMessagesForChannelId:channelId];
        NSLog(@"New chat message:%@", payload[fMessage]);
        
        return UNNotificationPresentationOptionSound;
    };
    PushBlock pushTypeChatInitiation = ^(id userInfo) {
        MessageCenter *center = [MessageCenter new];
        id payload = userInfo[fPayload];
        id channelId = payload[fChannelId];
        
        [MessageCenter checkSubscriptionToChannelId:channelId];
        [center addToSystemChannelId:channelId];
        [MessageCenter processFetchedMessagesForChannelId:channelId];
        NSLog(@"New chat initiation message:%@", payload[fMessage]);
        
        return UNNotificationPresentationOptionSound;
    };
    PushBlock pushTypeMessageRead = ^(id userInfo) {
        id payload = userInfo[fPayload];
        id messageId = payload[fMessageId];
        id channelId = payload[fChannelId];
        NSLog(@"Need to do something with %@ / %@", messageId, channelId);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", messageId];
        
        id message = [[[MessageCenter sortedMessagesForChannelId:channelId] filteredArrayUsingPredicate:predicate] firstObject];
        
        message[fRead] = @([message[fRead] integerValue] - 1);
        return UNNotificationPresentationOptionNone;
    };

    [self.pushHandlers setObject:pushTypeChannel forKey:@"pushTypeChannel"];
    [self.pushHandlers setObject:pushTypeMessage forKey:@"pushTypeMessage"];
    [self.pushHandlers setObject:pushTypeChatChannel forKey:@"pushTypeChatChannel"];
    [self.pushHandlers setObject:pushTypeChatInitiation forKey:@"pushTypeChatInitiation"];
    [self.pushHandlers setObject:pushTypeMessageRead forKey:@"pushTypeMessageRead"];
}

- (void) loadFiles
{
    self.chatsFile = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"chatFile"];

    self.channelsFile = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"channelFile"];
    
    self.chats = [NSMutableDictionary dictionaryWithContentsOfURL:self.chatsFile];
    self.channelUsers = [NSMutableDictionary dictionaryWithContentsOfURL:self.channelsFile];
    
    if (!self.chats) {
        self.chats = [NSMutableDictionary dictionary];
    }
    
    if (!self.channelUsers) {
        self.channelUsers = [NSMutableDictionary dictionary];
    }
    
    [self saveChatFile];
    [self saveChannelUsersFile];
}

+ (void)saveChats
{
    [[MessageCenter new] saveChatFile];
}

- (void) saveChatFile
{
    BOOL ret = [self.chats writeToURL:self.chatsFile atomically:YES];
    if (ret) {
        NSLog(@"Saved %@", self.chatsFile);
    }
    else {
        NSLog(@"ERROR: Writing to %@", self.chatsFile);
    }
}

- (void) saveChannelUsersFile
{
    BOOL ret = [self.channelUsers writeToURL:self.channelsFile atomically:YES];
    if (ret) {
        NSLog(@"Saved %@", self.channelsFile);
    }
    else {
        NSLog(@"ERROR: Writing to %@", self.channelsFile);
    }
}

+ (NSArray *)sortedMessagesForChannelId:(id)channelId
{
    return [[MessageCenter new] sortedMessagesForChannelId:channelId];
}

- (NSArray *)sortedMessagesForChannelId:(id)channelId
{
    NSAssert(channelId != nil, @"ChannelId cannot be nil");
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:fCreatedAt ascending:YES];
    
    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    return [messages sortedArrayUsingDescriptors:@[sd]];
}

- (NSMutableArray*) channelMessagesForChannelId:(id)channelId
{
    NSMutableArray *messages = [self.chats objectForKey:channelId];
    
    if (!messages) {
        messages = [NSMutableArray array];
        [self.chats setObject:messages forKey:channelId];
    }
    return messages;
}

- (BOOL) message:(id)objectId exists:(NSArray*)messages
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    NSArray *filter = [messages filteredArrayUsingPredicate:predicate];
    return (filter.count > 0);
}

- (NSArray*) userIds:(NSArray<User*>*)users
{
    NSMutableArray *array = [NSMutableArray new];
    
    for (User *user in users) {
        [array addObject:user.objectId];
    }
    
    return array;
}

- (void)sendPush:(Message*)message
           users:(NSArray<User*>*)users
      completion:(VoidBlock)action
{
    __LF
    NSAssert(action != nil, @"Completion handler cannot be nil");
    NSAssert(message != nil, @"Message cannot be nil");
    NSAssert(users != nil, @"Channel cannot be nil");

    id userIds = [self userIds:users];
    id channelId = message.channel.objectId;
    id messageId = message.objectId;
    id text = message.message;
    id senderId = [User me].objectId;
    
    id params = @{
                  fUsers : userIds,
                  fAlert : text,
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : @"pushTypeChatInitiation",
                  fPayload : @{
                          fSenderId: senderId, // must!!!
                          fMessage: message.dictionary,
                          fMessageId: messageId,
                          fChannelId: channelId,
                          fUsers : userIds,
                          },
                  };
    
    [PFCloud callFunctionInBackground:@"sendPushToUsers" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
        }
        else {
            NSLog(@"PUSH SENT:%@", object);
            action();
        }
    }];
}

- (void)sendPush:(Message*)message
       channelId:(id)channelId
      completion:(VoidBlock)action
{
    __LF
    NSAssert(action != nil, @"Completion handler cannot be nil");
    NSAssert(message != nil, @"Message cannot be nil");
    NSAssert(channelId != nil, @"ChannelId cannot be nil");

    id messageId = message.objectId;
    id text = message.message;
    id senderId = [User me].objectId;

    id params = @{
                  fChannel : channelId,
                  fAlert : text,
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : @"pushTypeChatChannel",
                  fPayload : @{
                          fSenderId: senderId, //Must!!!!
                          fMessage: message.dictionary,
                          fMessageId: messageId,
                          fChannelId : channelId,
                          },
                  };
    
    [PFCloud callFunctionInBackground:@"sendPushToChannel" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
        }
        else {
            NSLog(@"PUSH SENT:%@", object);
            action();
        }
    }];
}

+ (void)send:(id)msgToSend
     channelId:(id)channelId
       count:(NSUInteger)userCount
  completion:(AnyBlock)handler
{
    [[MessageCenter new] send:msgToSend
                    channelId:channelId
                        count:userCount
                   completion:handler];
}

- (void)send:(id)msgToSend
   channelId:(id)channelId
       count:(NSUInteger)userCount
  completion:(AnyBlock)handler
{
    if (msgToSend == nil) {
        if (handler) {
            handler(nil);
        }
        return;
    }

    Message *message = [Message message:msgToSend channelId:channelId count:userCount];
    
    id dictionary = message.dictionary;
    [dictionary setObject:@(NO) forKey:fSync];
    [dictionary setObject:[NSDate date] forKey:fCreatedAt];
    [dictionary setObject:[NSDate date] forKey:fUpdatedAt];
    
    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    [messages addObject:dictionary];
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
        else {
            [self sendPush:message channelId:channelId completion:^{
                id newDictionary = message.dictionary;
                [newDictionary setObject:@(YES) forKey:fSync];
                [messages removeObject:dictionary];
                [messages addObject:newDictionary];
                [self saveChatFile];
                if (handler) {
                    handler(newDictionary);
                }
            }];
        }
    }];
}

/*
 Sends message to a list of users and returns the channel (fully loaded) back through the completion handler.
 @param msgToSend the message to send
 @param handler channel block handler
 */

+ (NSString*) channelNameForChannelId:(id)channelId
{
    return [[MessageCenter new] channelNameForChannelId:channelId];
}

- (NSString*) channelNameForChannelId:(id)channelId
{
    id dictionary = [self.channelUsers objectForKey:channelId];
    
    NSArray *users = dictionary[fUsers];
    NSMutableSet *set = [NSMutableSet setWithArray:[users valueForKey:fNickname]];
    [set removeObject:[User me].nickname];
    return [[set allObjects] componentsJoinedByString:@", "];
}


+ (void)send:(id)msgToSend
       users:(NSArray *)users
  completion:(ChannelBlock)handler
{
    [[MessageCenter new] send:msgToSend users:users completion:handler];
}

- (void)send:(id)msgToSend
       users:(NSArray *)users
  completion:(ChannelBlock)handler
{
    if (msgToSend == nil) {
        if (handler) {
            handler(nil);
        }
        return;
    }
    
    Message *message = [Message message:msgToSend users:users];
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
        else {
            Channel* channel = message.channel;
            id channelId = channel.objectId;
            
            [MessageCenter checkSubscriptionToChannelId:channelId];
            
            [self sendPush:message users:users completion:^{
                id dictionary = message.dictionary;
                [dictionary setObject:@(YES) forKey:fSync];
                
                
                [self addMessage:dictionary channelId:channelId];
                [self addToSystemChannelId:channelId];
                [self saveChannelUsersFile];
                if (handler) {
                    handler(channel);
                }
            }];
        }
    }];
}

- (void) addMessage:(id)dictionary channelId:(id)channelId
{
    id messageId = dictionary[fObjectId];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", messageId];
    
    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    NSArray *included = [messages filteredArrayUsingPredicate:predicate];
    
    if (included.count == 0) {
        NSLog(@"Adding message:%@ to datastructure", messageId);
        dictionary[fSync] = @(NO);
        [messages addObject:dictionary];
        [self saveChatFile];
        PNOTIF(kNotificationNewChatMessage, dictionary);
        [MessageCenter setSystemBadge];
}
    else {
        NSLog(@"WARNING: Message:%@ already in datastructure", messageId);
    }
}

- (void) addToSystemChannelId:(id)channelId
{
    __LF
    
    [Channel fetch:channelId completion:^(Channel *channel) {
        id dictionary = channel.dictionary;
        [self.channelUsers setObject:dictionary forKey:channel.objectId];
        [self saveChannelUsersFile];
        PNOTIF(kNotificationNewChannelAdded, dictionary);
    }];
}

+ (id) channelIdForUser:(User*)user
{
    return [[MessageCenter new] channelIdForUser:user];
}

- (id) channelIdForUser:(User*)user
{
    id selectedUserId = user.objectId;
    
    for (id channelId in self.channelUsers.allKeys) {
        id channel = [self.channelUsers objectForKey:channelId];
        NSArray *users = channel[fUsers];
        
        BOOL found = NO;
        for (id user in users) {
            id userId = user[fObjectId];
            if ([userId isEqualToString:selectedUserId]) {
                found = YES;
                return channelId;
            }
        }
    }
    return nil;
}

+ (UNNotificationPresentationOptions)handlePushUserInfo:(id)userInfo
{
    MessageCenter *center = [MessageCenter new];
    
    UNNotificationPresentationOptions option = UNNotificationPresentationOptionNone;
    
    id pushType = userInfo[fPushType];
    id payload = userInfo[fPayload];
    id senderId = payload[fSenderId];
    
    NSLog(@"UserInfo:%@", userInfo);
    
    // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone
    
    if ([User meEquals:senderId]) {
        return option;
    }
    else {
        // Else parse pushType for handling.
        
        if ([pushType isEqualToString:@"pushTypeChannel"]) {
            option = UNNotificationPresentationOptionNone;
        }
        else if ([pushType isEqualToString:@"pushTypeMessage"]){
            option = UNNotificationPresentationOptionSound;
        }
        else if ([pushType isEqualToString:@"pushTypeChatChannel"]){
            option = UNNotificationPresentationOptionSound;
            id channelId = payload[fChannelId];

            if (![center.channelUsers objectForKey:channelId]) {
                [center addToSystemChannelId:channelId];
            }
            [self processFetchedMessagesForChannelId:channelId];
            NSLog(@"New chat message:%@", payload[fMessage]);
        }
        else if ([pushType isEqualToString:@"pushTypeChatInitiation"]){
            option = UNNotificationPresentationOptionSound;
            id channelId = payload[fChannelId];
        
            [self checkSubscriptionToChannelId:channelId];
            [center addToSystemChannelId:channelId];
            [self processFetchedMessagesForChannelId:channelId];
            NSLog(@"New chat initiation message:%@", payload[fMessage]);
        }
        else if ([pushType isEqualToString:@"pushTypeMessageRead"]) {
            id messageId = payload[fMessageId];
            id channelId = payload[fChannelId];
            NSLog(@"Need to do something with %@ / %@", messageId, channelId);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", messageId];
            
            id message = [[[MessageCenter sortedMessagesForChannelId:channelId] filteredArrayUsingPredicate:predicate] firstObject];
            
            message[fRead] = @([message[fRead] integerValue] - 1);
        }
        else {
            option = UNNotificationPresentationOptionNone;
        }
    }
    
    return option;
}

+ (void) processFetchedMessagesForChannelId:(id)channelId
{
    MessageCenter *center = [MessageCenter new];

    [self fetchMessagesForChannelId:channelId completion:^(NSArray *array) {
        for (Message *message in array) {
            id dictionary = message.dictionary;
            [center addMessage:dictionary channelId:channelId];
            [[History historyWithChannelId:channelId messageId:message.objectId] saveInBackground];
        }
    }];
}

+ (void) setSystemBadge
{
    NSUInteger count = [self countAllUnreadMessages];
    
    NSLog(@"Counted:%ld unread messages", count);
    PFInstallation *install = [PFInstallation currentInstallation];
    install.badge = count;
    [install saveInBackground];
}

+ (NSUInteger) countAllUnreadMessages
{
    MessageCenter *center = [MessageCenter new];
    NSUInteger count = 0;
    for (id channelId in center.chats.allKeys) {
        NSUInteger c = [MessageCenter countUnreadMessagesForChannelId:channelId];
        count += c;
    }
    return count;
}

+ (NSUInteger) countUnreadMessagesForChannelId:(id)channelId
{
    NSArray *messages = [MessageCenter sortedMessagesForChannelId:channelId];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync == FALSE"];
    return [messages filteredArrayUsingPredicate:predicate].count;
}

+ (void) fetchMessagesForChannelId:(id)channelId completion:(ArrayBlock)handler
{
    Channel *channel = [Channel objectWithoutDataWithObjectId:channelId];
    
    PFQuery *history = [History query];
    [history whereKey:fChannel equalTo:channel];
    [history whereKey:fUser equalTo:[User me]];
    
    PFQuery *query = [Message query];
    [query whereKey:fChannel equalTo:channel];
    [query includeKey:fFromUser];
    [query includeKey:fMedia];
    [query includeKey:fChannel];

    [query whereKey:fObjectId doesNotMatchKey:fMessageId inQuery:history];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            handler(objects);
        }
        else {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
    }];
}

+ (void) checkSubscriptionToChannelId:(id)channelId
{
    if (channelId) {
        PFInstallation *install = [PFInstallation currentInstallation];
        
        NSArray *channels = install.channels;
        if (![channels containsObject:channelId]) {
            [PFPush subscribeToChannelInBackground:channelId];
        }
    }
    else {
        NSLog(@"ERROR: Invalid Channel Id From Message");
    }
}

+ (NSArray *)channels
{
    return [MessageCenter new].channelUsers.allValues;
}

+ (void)removeChannelMessages:(id)channelId
{
    MessageCenter *center = [MessageCenter new];
    [center.channelUsers removeObjectForKey:channelId];
    [center saveChannelUsersFile];
}

/*
{
    channel =     {
        createdAt = "2017-05-14 04:25:36 +0000";
        createdBy = 5A5ajVmYII;
        name = iphone;
        objectId = 5Tio37Z9DD;
        updatedAt = "2017-05-14 04:26:01 +0000";
        users =         (
                         {
                             nickname = iphone;
                             objectId = GFjHKP0CsY;
                         },
                         {
                             nickname = "do you know me?";
                             objectId = 5A5ajVmYII;
                             thumbnail = "ProfileMedia/5A5ajVmYII/OWFVYC7K.jpg";
                         }
                         );
    };
    createdAt = "2017-05-14 04:28:35 +0000";
    fromUser =     {
        age = 40s;
        createdAt = "2017-04-30 11:16:05 +0000";
        desc = Ride;
        introduction = "Looking for girls";
        nickname = "do you know me?";
        objectId = 5A5ajVmYII;
        thumbnail = "ProfileMedia/5A5ajVmYII/OWFVYC7K.jpg";
        updatedAt = "2017-05-14 04:28:33 +0000";
        where = "{37.496038707246903, 127.0274715037569}";
        whereUpdatedAt = "2017-05-14 04:28:30 +0000";
    };
    message = Dddd;
    objectId = yBc3Mp4qwN;
    read = 1;
    sync = 1;
    type = 1;
    updatedAt = "2017-05-14 04:28:36 +0000";
}
*/
+ (void) processReadMessage:(id)message
{
    __LF
    if ([message[fSync] boolValue] == YES) {
        return;
    }
    message[fSync] = @(YES);
    [MessageCenter saveChats];
    
    id channel = message[fChannel];
    id channelId = channel[fObjectId];
    id messageId = message[fObjectId];
    id fromUser = message[fFromUser];
    id fromUserId = fromUser[fObjectId];
    
    if (channelId && messageId && fromUserId) {
        id params = @{
                      fChannelId : channelId,
                      fPushType : @"pushTypeMessageRead",
                      fPayload : @{
                              fSenderId : [User me].objectId, // Must!!!!!
                              fMessageId: messageId,
                              fChannelId : channelId,
                              },
                      };
        [PFCloud callFunctionInBackground:@"sendPushMessageRead" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR[%s]: SENDING SILENT PUSH:%@",__func__, error.localizedDescription);
            }
            else {
                NSLog(@"SILENT PUSH SENT:%@", object);
            }
        }];
    }
    else {
        NSLog(@"ERROR[%s]: ChannelId %@ or MessageId :%@ or fromUserId %@ missing.", __func__, channelId, messageId, fromUserId);
    }
}

@end

