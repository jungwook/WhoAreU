//
//  MessageCenter.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocket.h"

@interface MessageCenter : NSObject
/**
 Sends message to a list of users and returns the channel (fully loaded) back through the completion handler.
 @param msgToSend the message to send
 @param handler channel block handler
 */
+ (void)send:(id)msgToSend
       users:(NSArray*)users
  completion:(ChannelBlock)handler;

+ (void)send:(id)msgToSend
   channelId:(id)channelId
       count:(NSUInteger)userCount
  completion:(AnyBlock)handler;

/**
 Sends message to the connected websocket server.
 @param message either NSString or NSData object to send
 */
+ (void)        send:(id)message;

+ (void)        initializeCommunicationSystem;
+ (NSArray*)    liveChannels;
+ (NSArray*)    sortedMessagesForChannelId:(id)channelId;
+ (id)          lastJoinedChannelIdForUser:(User*)user;
+ (void)        removeChannelMessages:(id)channelId;

+ (void)        processFetchMessagesForChannelId:(id)channelId;
+ (void)        processFetchMessages;
+ (NSUInteger)  countAllUnreadMessages;
+ (NSUInteger)  countUnreadMessagesForChannelId:(id)channelId;
+ (void)        setSystemBadge;
+ (void)        saveChats;

+ (NSString*)   channelNameFromChannel:(id)dictionary;

+ (void)        processReadMessage:(id)message;

+ (void)        subscribeToChannelUser;
+ (void)        subscribeToChannel:(id)channel;
+ (void)        subscribeToUserChannel:(id)channel;
+ (void)        setupUserToInstallation;
+ (void)        registerSession;
+ (void)        sendMessageToNearbyUsers:(id)message;
+ (void)        sendSystemLogToNearbyUsers:(id)message;

/**
 *Asynchronously* get all the channels that this device is subscribed to.
 @param info userInfo retrieved from application delegate.
 */
+ (UNNotificationPresentationOptions) handlePushUserInfo:(id)info;
@end


