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
#import "WebSocket.h"

@interface MessageCenter()
@property (strong, nonatomic) NSMutableDictionary *chats;
@property (strong, nonatomic) NSMutableDictionary *channels;
@property (strong, nonatomic) NSURL *chatsFile, *channelsFile;
@property (strong, nonatomic) NSDictionary *pushHandlers;
@property (strong, nonatomic) WebSocket *socket;
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

- (void) setup
{
    __LF

    [self loadFiles];
    [self setupPushHandlers];
}

+ (void)initializeCommunicationSystem
{
    [[MessageCenter new] setupSocket];
}

+ (void) setupUserToInstallation
{
    PFInstallation *install = [PFInstallation currentInstallation];
    
    User *me = [User me];
    User *installUser = install[fUser];
    BOOL sameUser = [User meEquals:installUser.objectId];
    if (!sameUser) {
        me.credits = me.initialFreeCredits;
        NSLog(@"Adding %ld free credits", me.credits);
        [me saveInBackground];
        install[fUser] = me;
        NSLog(@"CURRENT INSTALLATION: saving user to Installation.");
        [install saveInBackground];
    }
    else {
        NSLog(@"CURRENT INSTALLATION: Installation is already set to current user. No need to update");
    }
}

+ (void) subscribeToChannelUser
{
    [self subscribeToChannel:[User me].objectId];
}

+ (void) subscribeToChannel:(id)channel
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    
    if (![installation.channels containsObject:channel]) {
        [PFPush subscribeToChannelInBackground:channel block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"application successfully subscribed to push notifications on the %@ channel.", channel);
            } else {
                NSLog(@"application failed to subscribe to push notifications on the %@ channel.", channel);
            }
        }];
    }
}

- (void) setupSocket
{
    __LF
    NSLog(@"User:%@", [User me]);
    self.socket = [WebSocket newWithId:[User me].objectId];
}

- (void) setupPushHandlers
{
    __LF

    self.pushHandlers = [NSMutableDictionary dictionary];

    PushHandlerBlock pushTypeChannelMessage = ^(id payload,
                                                id senderId,
                                                id channelId)
    {
        NSLog(@"payload:%@", payload);
        PNOTIF(kNotificationChannelMessage, payload);
        return UNNotificationPresentationOptionNone;
    };

    PushHandlerBlock pushTypeChannel = ^(id payload,
                                         id senderId,
                                         id channelId)
    {
        NSLog(@"payload:%@", payload);
        PNOTIF(kNotificationChannelMessage, payload);
        
        return UNNotificationPresentationOptionNone;
    };
    PushHandlerBlock pushTypeMessage = ^(id payload, id senderId, id channelId) {
        
        // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone
        
        if ([User meEquals:senderId]) {
            return UNNotificationPresentationOptionNone;
        }
        
        return UNNotificationPresentationOptionSound;
    };
    PushHandlerBlock pushTypeChatChannel = ^(id payload, id senderId, id channelId) {
        
        // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone
        
        if ([User meEquals:senderId] || channelId == nil) {
            return UNNotificationPresentationOptionNone;
        }
        
        [MessageCenter addChannelToSystem:channelId];
        [MessageCenter processFetchMessagesForChannelId:channelId];
        
        return UNNotificationPresentationOptionSound;
    };
    PushHandlerBlock pushTypeChatInitiation = ^(id payload, id senderId, id channelId) {

        // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone
        
        if ([User meEquals:senderId] || channelId == nil) {
            return UNNotificationPresentationOptionNone;
        }

        [MessageCenter addChannelToSystem:channelId];
        [MessageCenter processFetchMessagesForChannelId:channelId];
        
        return UNNotificationPresentationOptionSound;
    };
    PushHandlerBlock pushTypeMessageRead = ^(id payload, id senderId, id channelId) {

        // if push originated from me then do nothing and return option = UNNotificationPresentationOptionNone

        if ([User meEquals:senderId]) {
            return UNNotificationPresentationOptionNone;
        }
        
        id messageId = payload[fMessageId];
        if (messageId) {
            NSLog(@"Processing reads for %@", messageId);
            id message = [self messageWithId:messageId channelId:channelId];
            if (message) {
                [MessageCenter decreaseReadForMessage:message];
                [self saveChatFile];
                
                id ret = @{
                           fMessageId : messageId,
                           fChannelId : channelId,
                           };
                PNOTIF(kNotificationReadMessage, ret);
            }
        }
        
        return UNNotificationPresentationOptionNone;
    };
    
    self.pushHandlers = @{
                          kPushTypeChannelMessage : pushTypeChannelMessage,
                          kPushTypeChannel : pushTypeChannel,
                          kPushTypeMessage : pushTypeMessage,
                          kPushTypeMessageRead : pushTypeMessageRead,
                          kPushTypeChatChannel : pushTypeChatChannel,
                          kPushTypeChatInitiation : pushTypeChatInitiation,
                          };
}

+ (UNNotificationPresentationOptions)handlePushUserInfo:(id)userInfo
{
    __LF
    MessageCenter *center = [MessageCenter new];
    
    UNNotificationPresentationOptions option = UNNotificationPresentationOptionNone;
    
    id pushType = userInfo[fPushType];
    id payload = userInfo[fPayload];
    id senderId = payload[fSenderId];
    id channelId = payload[fChannelId];
    
    NSLog(@"UserInfo:%@", userInfo);
    
    PushHandlerBlock handler = [center.pushHandlers objectForKey:pushType];
    NSLog(@"Processing handler:%@ (%@)", pushType, handler);
    if (handler) {
        option = handler(payload, senderId, channelId);
    }
    
    return option;
}

- (void) loadFiles
{
    __LF

    self.chatsFile = FileURL(@"chatFile");
    self.channelsFile = FileURL(@"channelFile");
    
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
        NSLog(@"Saved %@", self.chatsFile);
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

- (NSArray*) userIds:(NSArray<User*>*)users
{
    return [users valueForKey:fObjectId];
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
                  fOperation : @"pushToUsers",
                  fUsers : userIds,
                  fAlert : @{
                          @"title" : [User me].nickname,
                          @"body" : text,
                          },
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : kPushTypeChatInitiation,
                  fSenderId : [User me].objectId,
                  fDescription : text,
                  fPayload : @{
                          fSenderId: senderId, // must!!!
                          fMessageId: messageId,
                          fChannelId: channelId,
                          fUsers : userIds,
                          },
                  };
    
    [self send:params];
    if (action) {
        action();
    }
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
                  fOperation : @"pushToChannel",
                  fChannel : channelId,
                  fAlert : @{
                          @"title" : [User me].nickname,
                          @"body" : text,
                          },
                  fBadge : @"increment",
                  fSound : @"default",
                  fPushType : kPushTypeChatChannel,
                  fSenderId : [User me].objectId,
                  fDescription : text,
                  fPayload : @{
                          fSenderId: senderId, //Must!!!!
                          fMessageId: messageId,
                          fChannelId : channelId,
                          },
                  };
    
    [self send:params];
    if (action) {
        action();
    }
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
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
        else {
            id dictionary = message.dictionary;
            id messageId = dictionary[fObjectId];

            // sync = YES to my message
            [MessageCenter setSyncForMessage:dictionary];

            [self addMessage:dictionary
                   channelId:channelId
            postNotification:YES];

            if (handler) {
                // return and run handler with messageId to chatView
                handler(messageId);
            }
            
            [self sendPush:message channelId:channelId completion:^{
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
            [MessageCenter subscribeToChannel:channelId];
            
            id dictionary = message.dictionary;

            // sync = YES to my message
            [MessageCenter setSyncForMessage:dictionary];
            
            [self addMessage:dictionary
                   channelId:channelId
            postNotification:YES];
            
            [self addChannelToSystem:channelId];
            if (handler) {
                // return channel so that payFor... can process performsegue to the chat channel.
                
                handler(channel);
            }
            
            [self sendPush:message users:users completion:^{
            }];
        }
    }];
    
    return;
}

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

- (void) addMessage:(id)dictionary
          channelId:(id)channelId
   postNotification:(BOOL)postNotification
{
    __LF
    
    if (!channelId) {
        return;
    }
    
    id messageId = dictionary[fObjectId];

    NSMutableArray *messages = [self channelMessagesForChannelId:channelId];
    
    if ([self messageWithId:messageId channelId:channelId]) {
        NSLog(@"WARNING: Message:%@ already in datastructure", messageId);
    }
    else {
        NSLog(@"Adding message:%@ to datastructure", messageId);
        [messages addObject:dictionary];
        [self saveChatFile];
        [[History historyWithChannelId:channelId messageId:messageId] saveInBackground];
        if (postNotification) {
            PNOTIF(kNotificationNewChatMessage, nil);
        }
        [MessageCenter setSystemBadge];
    }
}

+ (void) addChannelToSystem:(id) channelId
{
    [[MessageCenter new] addChannelToSystem:channelId];
}

- (void) addChannelToSystem:(id)channelId
{
    __LF
    [MessageCenter subscribeToChannel:channelId];

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

    [[MessageCenter new] saveChannelsFile];
}

+ (id) lastJoinedChannelIdForUser:(User*)user
{
    return [[MessageCenter new] lastJoinedChannelIdForUser:user];
}

- (id) lastJoinedChannelIdForUser:(User*)user
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

+ (void) processFetchMessages
{
    __LF
    
    MessageCenter *center = [MessageCenter new];
    
    [self fetchMessagesWithCompletion:^(NSArray *array) {
        NSLog(@"Loaded %ld messages to process", array.count);
        for (Message *message in array) {
            id dictionary = message.dictionary;
            
            NSLog(@"DICT:%@", dictionary);
            id channelId = message.channel.objectId;
            [self clearSyncForMessage:dictionary];
            [center addMessage:dictionary
                     channelId:channelId
              postNotification:NO];
        }
        PNOTIF(kNotificationNewChatMessage, nil);
        [self setSystemBadge];
    }];
}

+ (void) processFetchMessagesForChannelId:(id)channelId
{
    __LF
    
    MessageCenter *center = [MessageCenter new];

    [self fetchMessagesForChannelId:channelId completion:^(NSArray *array) {
        NSLog(@"Loaded %ld messages to process", array.count);
        for (Message *message in array) {
            id dictionary = message.dictionary;
            [self clearSyncForMessage:dictionary];
            [center addMessage:dictionary
                     channelId:channelId
              postNotification:NO];
        }
        PNOTIF(kNotificationNewChatMessage, nil);
        [self setSystemBadge];
    }];
}

+ (void) clearSyncForMessage:(id)message
{
    @synchronized (message) {
        message[fSync] = @(NO);
    }
}

+ (void) setSyncForMessage:(id)message
{
    @synchronized (message) {
        message[fSync] = @(YES);
    }
}

+ (void) decreaseReadForMessage:(id)message
{
    @synchronized (message) {
        NSInteger count = MAX((NSInteger)([message[fRead] integerValue] - 1), 0);
        message[fRead] = @(count);
    }
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
    MessageCenter *center = [MessageCenter new];
    NSUInteger count = 0;
    
    for (id channelId in center.channels.allKeys) {
        count += [MessageCenter countUnreadMessagesForChannelId:channelId];
    }
    
    return count;
}

+ (NSArray*) unreadMessagesForChannelId:(id)channelId
{
    NSArray *messages = [[MessageCenter new ] channelMessagesForChannelId:channelId];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync == FALSE AND objectId in SELF"];
    
    NSArray *unsynced = [messages filteredArrayUsingPredicate:predicate];
    
    return [unsynced valueForKey:fObjectId];
}

+ (NSUInteger) countUnreadMessagesForChannelId:(id)channelId
{
    return [self unreadMessagesForChannelId:channelId].count;
}

+ (void) fetchMessagesForChannelId:(id)channelId completion:(ArrayBlock)handler
{
    __LF

    Channel *channel = [Channel objectWithoutDataWithObjectId:channelId];
    
    PFQuery *history = [History query];
    [history whereKey:fChannel equalTo:channel];
    [history whereKey:fUser equalTo:[User me]];
    
    PFQuery *query = [Message query];
    [query whereKey:fFromUser notEqualTo:[User me]];
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

+ (void) fetchMessagesWithCompletion:(ArrayBlock)handler
{
    __LF
    
    PFQuery *history = [History query];
    [history whereKey:fUser equalTo:[User me]];
    
    PFQuery *query = [Message query];
    [query whereKey:fFromUser notEqualTo:[User me]];
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

+ (void) subscribeToUserChannel:(id)channel
{
    if (channel) {
        id param = @{
                     fOperation : fOperationSetChannel,
                     fChannel : channel,
                     };
        
        [self send:param];
    }
}

+ (void) registerSession
{
    id packet = @{
                  fOperation : fOperationRegistration,
                  fId        : [User me].objectId,
                  fWhen      : [NSDate date].stringUTC,
                  fMe        : [User me].simpleDictionary,
                  fChannel   : [User me].channel,
                  };
    
    [self send:packet];
}

+ (void) sendMessageToNearbyUsers:(id)message
{
    [self sendMessageToNearbyUsers:message type:fChannelTypeMessage];
}

+ (void) sendSystemLogToNearbyUsers:(id)message
{
    [self sendMessageToNearbyUsers:message type:fChannelTypeSystem];
}

+ (void) sendMessageToNearbyUsers:(id)message
                             type:(id)channelType
{
    BOOL simple = [message isKindOfClass:[NSString class]];
    id now = [NSDate date].stringUTC;
    id where = @{
                 fLatitude : @([User where].latitude),
                 fLongitude : @([User where].longitude),
                 };
    id messageString = simple ? (message ? message : @"") : (message[fMessage] ? message[fMessage] : @"");
    id type = simple ? @(kMessageTypeText) : @(kMessageTypeMedia);
    id media = simple ? @{} : message;
    
    id packet = @{
                  fOperation    : fChannelMessage,
                  fWhen         : now,
                  fWhere        : where,
                  fChannelType  : channelType,
                  fPayload      : @{
                          fMessage  : messageString,
                          fType     : type,
                          fMedia    : media,
                          },
                  };
    
    [self send:packet];
}

+ (void) processReadMessage:(id)message
{
    MessageCenter *center = [MessageCenter new];
    
    id messageId = [message objectForKey:fObjectId];
    id channel = [message objectForKey:fChannel];
    id users = [channel objectForKey:fUsers];
    id channelId = [channel objectForKey:fObjectId];
    id body = [message objectForKey:fMessage];
    
    BOOL sync = [message[fSync] boolValue];
    if (sync == NO && messageId && channelId && body) {
        [self setSyncForMessage:message];
        [self decreaseReadForMessage:message];
        NSLog(@"Read message: %@ (%@)",
              message[fMessage],
              message[fRead]);

        [MessageCenter saveChats];
        id userIds = [center userIds:users];
        NSLog(@"Sending ReadMessage to %@", userIds);
        id params = @{
                      fOperation : @"pushMessageRead",
                      fPushType : kPushTypeMessageRead,
                      fUsers : userIds,
                      fSenderId : [User me].objectId,
                      fDescription : body,
                      fPayload : @{
                              fMessageId: messageId,
                              fChannelId: channelId,
                              fMessage: body,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
                              },
                      };
        [center send:params];
    }
}

- (void)send:(id)message
{
    [self.socket send:message];
}

+ (void)send:(id)message
{
    MessageCenter *center = [MessageCenter new];
    [center send:message];
}
@end

