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
@property (strong, nonatomic) NSMutableDictionary *chats;
@property (strong, nonatomic) NSMutableDictionary *channels;
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
    __LF

    [self loadFiles];
    [self setupPushHandlers];
}

- (void) setupPushHandlers
{
    __LF

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
        
        [center addToSystemChannelId:channelId];
        [MessageCenter processFetchMessagesForChannelId:channelId];
        
        return UNNotificationPresentationOptionSound;
    };
    PushBlock pushTypeChatInitiation = ^(id userInfo) {
        MessageCenter *center = [MessageCenter new];
        id payload = userInfo[fPayload];
        id channelId = payload[fChannelId];
        
        [center addToSystemChannelId:channelId];
        [MessageCenter processFetchMessagesForChannelId:channelId];
        
        return UNNotificationPresentationOptionSound;
    };
    PushBlock pushTypeMessageRead = ^(id userInfo) {
        id payload = userInfo[fPayload];
        id channelId = payload[fChannelId];
        NSArray* reads = payload[fMessageIds];
        
        NSLog(@"Processing reads for %@", reads);
        for (id messageId in reads) {
            id message = [self messageWithId:messageId channelId:channelId];
            [MessageCenter decreaseReadForMessage:message];
        }
        [self saveChatFile];
        
        id ret = @{
                   fMessageIds : reads,
                   fChannelId : channelId,
                   };
        PNOTIF(kNotificationReadMessage, ret);
        return UNNotificationPresentationOptionNone;
    };

    [self.pushHandlers setObject:pushTypeChannel forKey:kPushTypeChannel];
    [self.pushHandlers setObject:pushTypeMessage forKey:kPushTypeMessage];
    [self.pushHandlers setObject:pushTypeChatChannel forKey:kPushTypeChatChannel];
    [self.pushHandlers setObject:pushTypeChatInitiation forKey:kPushTypeChatInitiation];
    [self.pushHandlers setObject:pushTypeMessageRead forKey:kPushTypeMessageRead];
}

- (void) loadFiles
{
    __LF

    self.chatsFile = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"chatFile"];

    self.channelsFile = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"channelFile"];
    
    self.chats = [NSMutableDictionary dictionaryWithContentsOfURL:self.chatsFile];
    self.channels = [NSMutableDictionary dictionaryWithContentsOfURL:self.channelsFile];
    
    if (!self.chats) {
        self.chats = [NSMutableDictionary dictionary];
    }
    
    if (!self.channels) {
        self.channels = [NSMutableDictionary dictionary];
    }
    
    for (id channelId in self.chats.allKeys) {
        if (![self.channels.allKeys containsObject:channelId]) {
            NSLog(@"Cleaning chats file by removing %@", channelId);
            [self.channels removeObjectForKey:channelId];
        }
    }
    
    [self saveChatFile];
    [self saveChannelsFile];
}

+ (void)saveChats
{
    [[MessageCenter new] saveChatFile];
}

- (void) saveChatFile
{
    __LF
    BOOL ret = [self.chats writeToURL:self.chatsFile atomically:YES];
    if (ret) {
//        NSLog(@"Saved %@", self.chatsFile);
    }
    else {
        NSLog(@"ERROR: Writing to %@", self.chatsFile);
    }
}

- (void) saveChannelsFile
{
    __LF
    BOOL ret = [self.channels writeToURL:self.channelsFile atomically:YES];
    if (ret) {
//        NSLog(@"Saved %@", self.channelsFile);
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

//- (BOOL) message:(id)objectId exists:(NSArray*)messages
//{
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
//    NSArray *filter = [messages filteredArrayUsingPredicate:predicate];
//    return (filter.count > 0);
//}

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
    id senderId = [User me].objectId;
    id text = message.message;
    
    id params = @{
                  fUsers : userIds,
                  fAlert : @{
                          @"title" : [User me].nickname,
                          @"body" : text,
                          },
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : kPushTypeChatInitiation,
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
                  fAlert : @{
                          @"title" : [User me].nickname,
                          @"body" : text,
                          },
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : kPushTypeChatChannel,
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
    __LF
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
    __LF

    if (msgToSend == nil) {
        if (handler) {
            handler(nil);
        }
        return;
    }

    Message *message = [Message message:msgToSend channelId:channelId count:userCount];
    
    NSDate *lastCreatedAt = [[self sortedMessagesForChannelId:channelId] lastObject][fCreatedAt];
    NSDate *now = [NSDate dateWithTimeIntervalSinceReferenceDate:MAX([NSDate date].timeIntervalSinceReferenceDate, lastCreatedAt.timeIntervalSinceReferenceDate)];
    
    id dictionary = message.dictionary;
    [dictionary setObject:@(NO) forKey:fSync];
    [dictionary setObject:now forKey:fCreatedAt];
    
    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    [messages addObject:dictionary];
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
        else {
            [self sendPush:message channelId:channelId completion:^{
                id newDictionary = message.dictionary;

                newDictionary[fSync] = @(YES);
                
                @synchronized (self.chats) {
                    [messages removeObject:dictionary];
                    [messages addObject:newDictionary];
                    [self saveChatFile];
                }
                
                id messageId = newDictionary[fObjectId];
                if (handler) {
                    handler(messageId);
                }
            }];
        }
    }];
    return;
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
    id dictionary = [self.channels objectForKey:channelId];
    
    NSArray *users = dictionary[fUsers];
    NSMutableSet *set = [NSMutableSet setWithArray:[users valueForKey:fNickname]];
    [set removeObject:[User me].nickname];
    return [[set allObjects] componentsJoinedByString:kStringCommaSpace];
}


+ (void)send:(id)msgToSend
       users:(NSArray *)users
  completion:(ChannelBlock)handler
{
    __LF

    [[MessageCenter new] send:msgToSend users:users completion:handler];
}

- (void)send:(id)msgToSend
       users:(NSArray *)users
  completion:(ChannelBlock)handler
{
    __LF
    
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
                dictionary[fSync] = @(YES);
                
                [self addMessage:dictionary
                       channelId:channelId
                            sync:YES];
                
                [self addToSystemChannelId:channelId];
                [self saveChannelsFile];
                if (handler) {
                    handler(channel);
                }
            }];
        }
    }];
    
    return;
}

- (void) addMessage:(id)dictionary
          channelId:(id)channelId
               sync:(BOOL)sync
{
    __LF
    
    id messageId = dictionary[fObjectId];

    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    
    if ([self messageWithId:messageId channelId:channelId]) {
        NSLog(@"WARNING: Message:%@ already in datastructure", messageId);
    }
    else {
        NSLog(@"Adding message:%@ to datastructure", messageId);
        NSLog(@"##################### SYNC TO %@", sync ? @"YES" : @"NO");
        dictionary[fSync] = @(sync);
        [messages addObject:dictionary];
        [self saveChatFile];
        PNOTIF(kNotificationNewChatMessage, dictionary);
        [MessageCenter setSystemBadge];
    }
}

- (void) addToSystemChannelId:(id)channelId
{
    __LF
    
    [MessageCenter checkSubscriptionToChannelId:channelId];

    // if channelId exists in the system then do nothing.
    if ([self.channels objectForKey:channelId]) {
        return;
    }
    
    [Channel fetch:channelId completion:^(Channel *channel) {
        id dictionary = channel.dictionary;
        [self.channels setObject:dictionary forKey:channel.objectId];
        [self saveChannelsFile];
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
    
    for (id channelId in self.channels.allKeys) {
        id channel = [self.channels objectForKey:channelId];
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
    __LF
    MessageCenter *center = [MessageCenter new];
    
    UNNotificationPresentationOptions option = UNNotificationPresentationOptionNone;
    
    id pushType = userInfo[fPushType];
    id payload = userInfo[fPayload];
    id senderId = payload[fSenderId];
    
//    NSLog(@"UserInfo:%@", userInfo);
    
    // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone
    
    if ([User meEquals:senderId]) {
        return option;
    }
    else {
        PushBlock handler = [center.pushHandlers objectForKey:pushType];
        if (handler) {
            NSLog(@"Processing handler:%@", pushType);
            option = handler(userInfo);
        }
    }
    
    return option;
}

+ (void) processFetchMessagesForChannelId:(id)channelId
{
    __LF
    
    MessageCenter *center = [MessageCenter new];

    [self fetchMessagesForChannelId:channelId completion:^(NSArray *array) {
        NSLog(@"Loaded %ld messages to process", array.count);
        for (Message *message in array) {
            id dictionary = message.dictionary;
            id messageId = message.objectId;
            [center addMessage:dictionary
                     channelId:channelId
                          sync:NO];
            [[History historyWithChannelId:channelId messageId:messageId] saveInBackground];
        }
    }];
}

+ (void) decreaseReadForMessage:(id)message
{
    @synchronized (message) {
        NSInteger count = MAX((NSInteger)([message[fRead] integerValue] - 1), 0);
        message[fRead] = @(count);
        [self saveChats];
    }
}

+ (void) decreaseReadForMessage:(id)message sync:(BOOL)sync
{
    @synchronized (message) {
        NSInteger count = MAX((NSInteger)([message[fRead] integerValue] - 1), 0);
        
        message[fSync] = @(sync);
        message[fRead] = @(count);
        [self saveChats];
    }
}

+ (void) acknowledgeReadsForChannelId:(id)channelId
{
    __LF
    
    if (channelId) {
        NSArray *reads = [self readsForChannelId:channelId];
       
        if (reads.count == 0) {
            return;
        }
        
        NSLog(@"ACKing %@", reads);
        
        
        id params = @{
                      fChannelId : channelId,
                      fPushType : kPushTypeMessageRead,
                      fPayload : @{
                              fSenderId  : [User me].objectId,
                              fMessageIds: reads,
                              fChannelId : channelId,
                              },
                      };
        
        NSLog(@"params:%@", params);
        [PFCloud callFunctionInBackground:@"sendPushMessageRead" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR[%s]: SENDING SILENT PUSH:%@",__func__, error.localizedDescription);
            }
            else {
                NSLog(@"SILENT PUSH SENT[%@] FOR:%@", reads, channelId);
                
                for (id messageId in reads) {
                    id message = [self messageWithId:messageId channelId:channelId];
                    [self decreaseReadForMessage:message sync:YES];
                }
                NSLog(@"Remaining reads %@", [self readsForChannelId:channelId]);
                [self saveChats];
                
                id ret = @{
                           fMessageIds : reads,
                           fChannelId : channelId,
                           };
                PNOTIF(kNotificationReadMessage, ret);
                [MessageCenter setSystemBadge];
            }
        }];
    }
    else {
        NSLog(@"ERROR[%s]: ChannelId %@ missing.", __func__, channelId);
    }

}

+ (NSArray*) readsForChannelId:(id)channelId
{
    NSArray *messages = [MessageCenter sortedMessagesForChannelId:channelId];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync == FALSE"];
    
    NSArray *unsynced = [messages filteredArrayUsingPredicate:predicate];

    return [unsynced valueForKey:fObjectId];
}

+ (void) setSystemBadge
{
    __LF

    NSUInteger count = [self countAllUnreadMessages];
    
    NSLog(@"Counted:%ld unread messages", count);
    PFInstallation *install = [PFInstallation currentInstallation];
    install.badge = count;
    [install saveInBackground];
}

+ (NSUInteger) countAllUnreadMessages
{
    __LF

    MessageCenter *center = [MessageCenter new];
    NSUInteger count = 0;
    
    for (id channelId in center.channels.allKeys) {
        count += [MessageCenter countUnreadMessagesForChannelId:channelId];
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
    __LF

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
    __LF

    if (channelId) {
        PFInstallation *install = [PFInstallation currentInstallation];
        
        if (![install.channels containsObject:channelId]) {
            [PFPush subscribeToChannelInBackground:channelId];
        }
    }
    else {
        NSLog(@"ERROR: Invalid Channel Id From Message");
    }
}

+ (NSArray *)liveChannels
{
    return [MessageCenter new].channels.allValues;
}

+ (void)removeChannelMessages:(id)channelId
{
    __LF
    
    MessageCenter *center = [MessageCenter new];
    [center.channels removeObjectForKey:channelId];
    [center.chats removeObjectForKey:channelId];
    [center saveChannelsFile];
    [center saveChatFile];
}

+ (id) messageWithId:(id)messageId channelId:(id)channelId
{
    return [[MessageCenter new] messageWithId:messageId channelId:channelId];
}

- (id) messageWithId:(id)messageId channelId:(id)channelId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", messageId];
 
    return [[[self.chats objectForKey:channelId] filteredArrayUsingPredicate:predicate] firstObject];
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
    return;
    
    __LF
    
    /*
     This is the point where a row is read for the first time. So if the message is not mine, and proper then send a silent push to channel providing a the readcount.
        Read counts are managed separately by each client...
     This is a nice to have and not a proper value. (i.e. DB value doesn't really mean anything.
    */
    
    id messageId    = message[fObjectId];
//    id channel      = message[fChannel];
//    id channelId    = channel[fObjectId];
    id fromUser     = message[fFromUser];
    id fromUserId   = fromUser[fObjectId];

    if ([User meEquals:fromUserId]) {
        NSLog(@">>>push from me... pass");
        return;
    }
    
    if ([message[fSync] boolValue] == YES) {
        NSLog(@">>>Sync == YES");
        return;
    }
    
    if (messageId == nil) {
        NSLog(@">>>No messageId. new object before save");
        return;
    }

    __LF

    /*
   
    // Syncing message as read.
    NSLog(@"##################### SYNC TO YES");
    message[fSync] = @(YES);
    [MessageCenter saveChats];
    if (channelId && fromUserId) {
        id params = @{
                      fChannelId : channelId,
                      fPushType : kPushTypeMessageRead,
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
                NSLog(@"SILENT PUSH SENT[%@] TO:%@", messageId, channelId);
                
                message[fRead] = @([message[fRead] integerValue] - 1);
                
                id ret = @{
                           fMessageId : messageId,
                           fChannelId : channelId,
                           };
                PNOTIF(kNotificationReadMessage, ret);
                [MessageCenter setSystemBadge];
            }
        }];
    }
    else {
        NSLog(@"ERROR[%s]: ChannelId %@ or or fromUserId %@ missing.", __func__, channelId, fromUserId);
    }
 */
}

@end

