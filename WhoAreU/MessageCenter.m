//
//  MessageCenter.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MessageCenter.h"
#import "S3File.h"

@interface MessageCenter()
@property (strong, nonatomic) NSMutableDictionary *chats, *channelUsers;
@property (strong, nonatomic) NSURL *chatsFile, *channelsFile;
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
    [self loadFiles];
    
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
}

- (void) saveFiles
{
    BOOL ret = [self.chats writeToURL:self.chatsFile atomically:YES];
    ret &= [self.channelUsers writeToURL:self.channelsFile atomically:YES];
    if (ret) {
        NSLog(@"Saved %@", self.chatsFile);
        NSLog(@"Saved %@", self.channelsFile);
    }
    else {
        NSLog(@"ERROR: Writing to %@", self.chatsFile);
    }
}

+ (NSArray *)sortedMessages:(Channel *)channel
{
    return [[MessageCenter new] sortedMessages:channel];
}

- (NSArray *) sortedMessages:(Channel*)channel
{
    NSAssert(channel != nil, @"Channel cannot be nil");
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    
    NSMutableArray *messages = [self channelMessages:channel];
    return [messages sortedArrayUsingDescriptors:@[sd]];
}

- (NSMutableArray*) channelMessages:(Channel*)channel
{
    NSMutableArray *messages = [self.chats objectForKey:channel.objectId];
    
    if (!messages) {
        messages = [NSMutableArray array];
        [self.chats setObject:messages forKey:channel.objectId];
    }
    return messages;
}

- (BOOL) message:(id)objectId exists:(NSArray*)messages
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    NSArray *filter = [messages filteredArrayUsingPredicate:predicate];
    return (filter.count > 0);
}

- (void)sendPush:(Message*)message channel:(Channel*)channel completion:(VoidBlock)action
{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (action) {
            action();
        }
    });
}

+ (void)send:(id)msgToSend
     channel:(Channel *)channel
  completion:(AnyBlock)handler
{
    [[MessageCenter new] send:msgToSend channel:channel completion:handler];
}

- (void)send:(id)msgToSend
     channel:(Channel *)channel
  completion:(AnyBlock)handler
{
    if (msgToSend == nil) {
        if (handler) {
            handler(nil);
        }
        return;
    }
    
    Message *message = [Message message:msgToSend channel:channel];
    
    id dictionary = message.dictionary;
    [dictionary setObject:@(NO) forKey:@"sync"];
    [dictionary setObject:[NSDate date] forKey:@"createdAt"];
    [dictionary setObject:[NSDate date] forKey:@"updatedAt"];
    
    NSMutableArray *messages = [self channelMessages:channel];
    
    [messages addObject:dictionary];
    [self saveFiles];
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:[%s]%@", __func__, [error localizedDescription]);
        }
        else {
            [self sendPush:message channel:channel completion:^{
                id newDictionary = message.dictionary;
                [newDictionary setObject:@(YES) forKey:@"sync"];
                [messages removeObject:dictionary];
                [messages addObject:newDictionary];
                [self saveFiles];
                if (handler) {
                    handler(newDictionary);
                }
            }];
        }
    }];
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
            [self sendPush:message channel:message.channel completion:^{
                id dictionary = message.dictionary;
                Channel* channel = message.channel;
                
                [dictionary setObject:@(YES) forKey:@"sync"];
                
                NSMutableArray *messages = [self channelMessages:message.channel];
                [messages addObject:dictionary];
                
                [self addToSystemChannel:channel];
                [self saveFiles];
                if (handler) {
                    handler(channel);
                }
            }];
        }
    }];
}

- (void) addToSystemChannel:(Channel*)channel
{
    NSMutableArray *array = [NSMutableArray new];
    
    for (User *user in channel.users) {
        [array addObject:user.objectId];
    }
    [self.channelUsers setObject:array forKey:channel.objectId];
}

+ (id) channelIdForUser:(User*)user
{
    return [[MessageCenter new] channelIdForUser:user];
}

- (id) channelIdForUser:(User*)user
{
    id userId = user.objectId;
    
    for (id channelId in self.channelUsers.allKeys) {
        NSArray *users = [self.channelUsers objectForKey:channelId];
        if ([users containsObject:userId]) {
            return channelId;
        };
    }
    return nil;
}

@end

