//
//  MessageCenter.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageCenter : NSObject

+ (void)send:(id)msgToSend
       users:(NSArray*)users
  completion:(ChannelBlock)handler;

+ (void)send:(id)msgToSend
       channel:(Channel*)channel
  completion:(AnyBlock)handler;

+ (NSArray *)   sortedMessages:(Channel*)channel;
+ (id)          channelIdForUser:(User*)user;
@end


