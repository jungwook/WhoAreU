//
//  MessageCenter.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

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

+ (NSArray*)    liveChannels;
+ (NSArray *)   sortedMessagesForChannelId:(id)channelId;
+ (id)          channelIdForUser:(User*)user;
+ (void)        removeChannelMessages:(id)channelId;
+ (NSUInteger)  countUnreadMessagesForChannelId:(id)channelId;
+ (void)        setSystemBadge;
+ (void)        saveChats;
+ (NSString*)   channelNameForChannelId:(id)channelId;
+ (void)        processReadMessage:(id)message;
+ (id)          messageWithId:(id)messageId channelId:(id)channelId;
+ (void)        acknowledgeReadsForChannelId:(id)channelId;

/**
 *Asynchronously* get all the channels that this device is subscribed to.
 @param info userInfo retrieved from application delegate.
 */
+ (UNNotificationPresentationOptions) handlePushUserInfo:(id)info;
@end


