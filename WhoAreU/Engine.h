//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNotificationNewUserMessage @"NotificationNewUserMessage"
#define kNotificationNewChannelMessage @"NotificationNewChannelMessage"
#define kNotificationUserLoggedInMessage @"NotificationUserLoggedIn"
#define kNotificationSystemInitialized @"NotifictionSystemInitialized"

#define SIMULATOR_FETCH_INTERVAL 10.0f
#define CHAT_FILE_PATH @"Chats"
#define CHANNEL_FILE_PATH @"ChannelMessages"

typedef enum : NSUInteger {
    kSimulatorStatusUnknown = 0,
    kSimulatorStatusSimulator,
    kSimulatorStatusDevice,
} SimulatorStatus;

@interface Counter : NSObject
@property (strong, nonatomic) NSMutableDictionary *counters;
- (id) setCount:(NSUInteger)count completion:(VoidBlock)handler;
- (void) decreaseCount:(id)counterId;
@end

@interface Queue : NSObject
@property (nonatomic, readonly) NSArray* objects;
@property (nonatomic, readonly) NSUInteger count;
+ (instancetype)new;
+ (instancetype)initWithCapacity:(NSUInteger)numItems;
+ (NSArray*) objects;
+ (NSUInteger)count;
- (void) addObject:(id)anObject;
+ (void) addObject:(id)anObject;
+ (void)clear;
- (void)clear;
- (id) objectAtIndex:(NSUInteger)index;
+ (id) objectAtIndex:(NSUInteger)index;
@end

@interface Engine : NSObject
@property (nonatomic) BOOL initialized;
@property (nonatomic) SimulatorStatus simulatorStatus;
+ (PFGeoPoint*) where;
+ (void) initializeSystems;
+ (CLLocationDirection) heading;

+ (void) postNewUserMessageNotification:(id)userInfo;
+ (void) postNewChannelMessageNotification:(id)userInfo;

//+ (void) deleteChatWithUserId:(id)userId;
//+ (void) sendChannelMessage:(NSString*)message;
//+ (UNNotificationPresentationOptions) handlePushUserInfo:(id)userInfo;
//+ (NSArray*) chatUserIds;
//+ (void) save;
//+ (NSArray*) messagesFromUser:(User*)user;
//+ (void) fetchOutstandingMessages;
//+ (BOOL) userExists:(User*)user;
//+ (NSUInteger) unreadMessagesFromUser:(User*)user;
//+ (void) readMessage:(MessageDic*)dictionary;
//+ (void) countUnreadMessagesFromUser:(User*)user completion:(CountBlock)handler;
//+ (void) countUnreadMessages:(CountBlock)handler;
//+ (void) loadUnreadMessagesFromUser:(User*)user completion:(VoidBlock)handler;
//+ (void) send:(id)msgToSend toUser:(User*)user completion:(VoidBlock)handler;
//+ (void) setSystemBadge;

@end
