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
#define fIntroduction @"introduction"
#define fSync @"sync"
#define fRead @"read"
#define fSenderId @"senderId"
#define fMessageId @"messageId"
#define fMessageIds @"messageIds"
#define fPayload @"payload"
#define fPushType @"pushType"
#define fAlert @"alert"
#define fBadge @"badge"
#define fSound @"sound"
#define fType @"type"
#define fOnId @"onId"
#define fSource @"source"
#define fSize @"size"
#define fUserId @"userId"
#define fComment @"comment"
#define fName @"name"
#define fOperation @"operation"
#define fDescription @"description"
#define fLatitude @"latitude"
#define fLongitude @"longitude"
#define fId @"id"
#define fWhen @"when"
#define fMe @"me"
#define fDistance @"distance"
#define fGender @"gender"
#define fChannelType @"channelType"
#define fPushHiToUsersNearMe @"pushHiToUsersNearMe"
#define fChannelMessage @"channelMessage"
#define fChannelTypeMessage @"message"
#define fChannelTypeSystem @"system"
#define fChannelTypeSetup @"setup"
#define fOperationSetChannel @"setChannel"
#define fOperationRegistration @"registration"
#define fSelectedTabBarIndex @"selectedTabBarIndex"
#define fBadge @"badge"

#define fTitle @"title"
#define fAttributedTitle @"attributedTitle"
#define fItems @"items"
#define fIcons @"icons"
#define fIcon @"icon"
#define fDeselectedIcon @"deselectedIcon"
#define fNavigationControllerNotRequired @"navigationControllerNotRequired"
#define fViewController @"viewController"

#define kStringNull @""
#define kStringSpace @" "
#define kStringCommaSpace @", "

#define kPushTypeMessageRead @"pushTypeMessageRead"
#define kPushTypeChatInitiation @"pushTypeChatInitiation"
#define kPushTypeChatChannel @"pushTypeChatChannel"
#define kPushTypeMessage @"pushTypeMessage"
#define kPushTypeChannel @"pushTypeChannel"
#define kPushTypeChannelMessage @"pushTypeChannelMessage"

#define kNotificationUserLoggedInMessage @"NotificationUserLoggedIn"
#define kNotificationUserMediaUpdated @"NotificationUserMediaUpdated"
#define kNotificationSystemInitialized @"NotifictionSystemInitialized"
#define kNotificationNewChannelAdded @"NotificationNewChannelAdded"
#define kNotificationNewChatMessage @"NotificationNewChatMessage"
#define kNotificationReadMessage @"NotificationReadMessage"
#define kNotificationApplicationActive @"NotificationApplicationBecameActive"
#define kNotificationEndEditing @"NotificationEndEditing"
#define kNotificationChannelMessage @"NotificationChannelMessage"

#define kJPEGCompressionLow 0.2f
#define kJPEGCompressionMedium 0.4f
#define kJPEGCompressionDefault 0.6f
#define kJPEGCompressionFull 1.0f
#define kThumbnailWidth 100

#define kVideoThumbnailWidth 320

//#define __LF NSLog(@"%s", __FUNCTION__);

#define NSLog(FORMAT, ...) fprintf(stderr,"LOG>> %s %s\n", __func__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
//#define __LF NSLog(@"%s", __func__);
#define __LF NSLog(@"");

#define WSLOCATION @"http://parse.kr:8080"
//#define WSLOCATION @"http://localhost:8080"
#define S3LOCATION @"http://whoareu.s3.ap-northeast-2.amazonaws.com/"

#define FileURL(__X__) [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:__X__]

#define LogError NSLog(@"ERROR[%s]:%@", __func__, error.localizedDescription);

#define SIMULATOR_FETCH_INTERVAL 10.0f
#define ASSERT_NOT_NULL(__A__) NSAssert(__A__, @"__A__ cannot be nil")
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define degreesToRadians(__x__) (M_PI * __x__ / 180.0f)
#define radiansToDegrees(__x__) (__x__ * 180.0f / M_PI)

#define Notification(__X__,__Y__) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__Y__) name:__X__ object:nil]
#define RemoveAllNotifications [[NSNotificationCenter defaultCenter] removeObserver:self]
#define PostNotification(__X__, __Y__) [[NSNotificationCenter defaultCenter] postNotificationName:__X__ object:__Y__]

#define Coords2DFromPoint(__x__) CLLocationCoordinate2DMake(__x__.latitude, __x__.longitude)
#define LocationFromPoint(__X__) [[CLLocation alloc] initWithLatitude:__X__.latitude longitude:__X__.longitude]
#define LocationFromCoords(__X__) [[CLLocation alloc] initWithLatitude:__X__.latitude longitude:__X__.longitude]
#define PointFromCLLocation(__X__) [PFGeoPoint geoPointWithLocation:__X__]
#define PointFromCoords2D(__X__) [PFGeoPoint geoPointWithLatitude:__X__.latitude longitude:__X__.longitude]

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
typedef void(^SelectedIndexBlock)(NSUInteger index);
typedef void(^IndexBlock)(NSUInteger index);
typedef void(^SectionIndexBlock)(NSUInteger section, NSUInteger index);
typedef void(^UserViewRectBlock)(User * user, UIView* view, CGRect rect);
typedef void(^UserBlock)(User* user);
typedef void(^ImageBlock)(UIImage* image);
typedef void(^ArrayBlock)(NSArray* array);
typedef void(^ObjectIndexBlock)(id object, NSUInteger idx);
typedef void(^StringBlock)(NSString* string);
typedef void(^MediaBlock)(Media *media);
typedef void(^KeyboardEventBlock)(CGFloat duration,UIViewAnimationOptions options, CGRect keyboardFrame);
typedef void(^FloatEventBlock)(CGFloat value);
typedef void(^AlertAction)(UIAlertAction *action);
typedef void(^ErrorBlock)(NSError* error);
typedef UNNotificationPresentationOptions(^PushBlock)(id message);
typedef UNNotificationPresentationOptions(^PushHandlerBlock)(id payload, id senderId, id channelId);



#endif /* Definitions_h */
