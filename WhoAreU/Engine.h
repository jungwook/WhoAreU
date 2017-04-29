//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kNOTIFICATION_NEW_MESSAGE @"NewMessageNotification"

@interface Engine : NSObject
+ (PFGeoPoint*) where;
+ (void) initializeSystems;
+ (NSArray*) chatUsers;
+ (void) send:(id)message toUser:(User*)user;
+ (NSArray*) messagesFromUser:(User*)user;
@end
