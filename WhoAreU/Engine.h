//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kNOTIFICATION_NEW_MESSAGE @"NewMessageNotification"
#define SIMULATOR_FETCH_INTERVAL 10.0f

typedef enum : NSUInteger {
    kSimulatorStatusUnknown = 0,
    kSimulatorStatusSimulator,
    kSimulatorStatusDevice,
} SimulatorStatus;

@interface Engine : NSObject
@property (nonatomic) BOOL initialized;
@property (nonatomic) SimulatorStatus simulatorStatus;
+ (PFGeoPoint*) where;
+ (void) initializeSystems;
+ (NSArray*) chatUserIds;
+ (void) save;
+ (NSArray*) messagesFromUser:(User*)user;
+ (void) fetchOutstandingMessages;
//+ (void) loadMessage:(id)messageId;
+ (BOOL) userExists:(User*)user;
+ (NSUInteger) unreadMessagesFromUser:(User*)user;
+ (void) readMessage:(MessageDic*)dictionary;
+ (void) countUnreadMessagesFromUser:(User*)user completion:(CountBlock)handler;
+ (void) countUnreadMessages:(CountBlock)handler;
+ (void) loadUnreadMessagesFromUser:(User*)user completion:(VoidBlock)handler;
+ (void) postNewMessageNotification:(id)userInfo;
+ (void) send:(id)msgToSend toUser:(User*)user completion:(VoidBlock)handler;
+ (void) setSystemBadge;
+ (CLLocationDirection) heading;
+ (void) deleteChatWithUserId:(id)userId;
@end
