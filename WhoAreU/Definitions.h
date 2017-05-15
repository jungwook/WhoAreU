//
//  Definitions.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 13..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#ifndef Definitions_h
#define Definitions_h

#define fObjectId @"objectId"
#define fUsers @"users"
#define fUser @"user"
#define fThumbnail @"thumbnail"
#define fMessage @"message"
#define fUpdatedAt @"updatedAt"
#define fCreatedAt @"createdAt"
#define fMedia @"media"
#define fCreatedBy @"createdBy"
#define fChannel @"channel"
#define fChannelId @"channelId"
#define fFromUser @"fromUser"
#define fFromUserId @"fromUserId"
#define fNickname @"nickname"
#define fLikes @"likes"
#define fWhere @"where"
#define fWhereUpdatedAt @"whereUpdatedAt"
#define fPhotos @"photos"
#define fAge @"age"
#define fDesc @"desc"
#define fIntroduction @"introduction"
#define fSync @"sync"
#define fRead @"read"
#define fSenderId @"senderId"
#define fMessageId @"messageId"
#define fPayload @"payload"
#define fPushType @"pushType"
#define fAlert @"alert"
#define fBadge @"badge"
#define fSound @"sound"


#define kNotificationUserLoggedInMessage @"NotificationUserLoggedIn"
#define kNotificationSystemInitialized @"NotifictionSystemInitialized"
#define kNotificationNewChannelAdded @"NotificationNewChannelAdded"
#define kNotificationNewChatMessage @"NotificationNewChatMessage"

#define kJPEGCompressionLow 0.2f
#define kJPEGCompressionMedium 0.4f
#define kJPEGCompressionDefault 0.6f
#define kJPEGCompressionFull 1.0f
#define kThumbnailWidth 100

#define kVideoThumbnailWidth 320
#define S3LOCATION @"http://whoareu.s3.ap-northeast-2.amazonaws.com/"
#define SIMULATOR_FETCH_INTERVAL 10.0f
#define ASSERT_NOT_NULL(__A__) NSAssert(__A__, @"__A__ cannot be nil")
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define __LF NSLog(@"%s", __FUNCTION__);


#define ANOTIF(__X__,__Y__) [[NSNotificationCenter defaultCenter] addObserver:self selector:__Y__ name:__X__ object:nil]

#define RNOTIF(__Y__) [[NSNotificationCenter defaultCenter] removeObserver:self name:__Y__ object:nil]
#define RANOTIF [[NSNotificationCenter defaultCenter] removeObserver:self]
#define PNOTIF(__X__, __Y__) [[NSNotificationCenter defaultCenter] postNotificationName:__X__ object:__Y__]

#define POINT_FROM_CLLOCATION(__X__) [PFGeoPoint geoPointWithLocation:__X__]
#define POINT_FROM_COORDINATES(__X__) [PFGeoPoint geoPointWithLatitude:__X__.latitude longitude:__X__.longitude]
#define SIMULATOR_LOCATION [PFGeoPoint geoPointWithLatitude:37.515791f longitude:127.027807f]

#define kAppColor [UIColor colorWithRed:95/255.f green:167/255.f blue:229/255.f alpha:1.0f]
#define appScreen [UIScreen mainScreen]
#define appWindow [UIApplication sharedApplication].keyWindow
#define mainWindow [[[UIApplication sharedApplication] delegate] window]


@class User;
@class Media;
@class Message;
@class Channel;

typedef void(^BOOLBlock)(BOOL value);
typedef void(^AnyBlock)(id object);
typedef void(^ChannelBlock)(Channel* channel);
typedef void(^VoidBlock)(void);
typedef void(^CountBlock)(NSUInteger count);
typedef void(^UserBlock)(User* user);
typedef void(^ImageBlock)(UIImage* image);
typedef void(^ArrayBlock)(NSArray* array);
typedef void(^StringBlock)(NSString* string);
typedef void(^MediaBlock)(Media *media);
typedef void(^KeyboardEventBlock)(CGFloat duration,UIViewAnimationOptions options, CGRect keyboardFrame);
typedef void(^FloatEventBlock)(CGFloat value);
typedef void(^AlertAction)(UIAlertAction *action);


#endif /* Definitions_h */
