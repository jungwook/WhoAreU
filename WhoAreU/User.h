//
//  User.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Parse/Parse.h>

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

typedef NS_OPTIONS(NSUInteger, GenderType)
{
    kGenderTypeMale = 0,
    kGenderTypeFemale,
    kGenderTypeUnknown,
};

typedef NS_OPTIONS(BOOL, MediaType)
{
    kMediaTypePhoto = 0,
    kMediaTypeVideo
};

typedef NS_OPTIONS(NSUInteger, SourceType)
{
    kSourceUploaded = 0,
    kSourceTaken,
};

typedef NS_OPTIONS(NSUInteger, MessageType)
{
    kMessageTypeUnknown = 0,
    kMessageTypeText,
    kMessageTypeMedia,
};

#pragma mark Message

#define ASSERT_NOT_NULL(__A__) NSAssert(__A__, @"__A__ cannot be nil")


//typedef NSMutableDictionary MessageDic;
//typedef NSMutableDictionary MediaDic;
//
//@interface NSMutableDictionary(Dictionary)
//@property (nonatomic, assign) NSString* objectId;
//@property (nonatomic, assign) NSDate*   createdAt;
//@property (nonatomic, assign) NSDate*   updatedAt;
//@property (nonatomic, assign) NSString* userId;
//@property (nonatomic, assign) NSString* channelId;
//@property (nonatomic, assign) NSString* comment;
//@property (nonatomic, assign) NSString* thumbnail;
//@property (nonatomic, assign) NSString* mediaFile;
//@property MediaType mediaType;
//@property CGSize size;
//@property BOOL source;
//@property BOOL sync;
//
//@property (nonatomic, assign) NSString* fromUserId;
//@property (nonatomic, assign) NSString* toUserId;
//@property (nonatomic, assign) NSString* message;
//@property (nonatomic, assign) MediaDic*    media;
//@property MessageType messageType;
//@property BOOL read;
//@end

@interface Channel : PFObject <PFSubclassing>
@property (retain) NSString *name;
@property (retain) User* createdBy;
@property (retain) NSArray <User*>*users;

- (id)dictionary;

- (void) addUsers:(NSArray<User*>*)users
       completion:(VoidBlock)action;
- (void) removeUsers:(NSArray<User*>*)users
          completion:(VoidBlock)action;
- (void) removeUser:(User*)user
         completion:(VoidBlock)action;

+ (instancetype) newWithUsers:(NSArray*)users;
@end

@interface Message : PFObject <PFSubclassing>
@property (retain) User *fromUser;
@property (retain) Channel *channel;
@property (retain) NSString* message;
@property (retain) Media* media;
@property MessageType type;
@property BOOL read;

- (id)dictionary;

+ (instancetype)message:(id)object
                  users:(NSArray*)users;
+ (instancetype)message:(id)object
                channel:(Channel*)channel;
@end

#pragma mark Media

@interface Media : PFObject <PFSubclassing>
@property (retain) NSString* userId;
@property (retain) NSString* comment;
@property (retain) NSString* thumbnail;
@property (retain) NSString* media;
@property MediaType type;
@property CGSize size;
@property BOOL source;

- (id)dictionary;

- (void) fetched:(VoidBlock)handler;
- (void) saved:(VoidBlock)handler;
- (void) imageLoaded:(ImageBlock)block;
- (void) thumbnailLoaded:(ImageBlock)block;
@end

#pragma mark User

@interface User : PFUser <PFSubclassing>
@property (retain) NSString*    nickname;
@property (retain) PFGeoPoint*  where;
@property (retain) NSDate*      whereUdatedAt;
@property (retain) NSString*    age;
@property (retain) NSString*    desc;
@property (retain) NSString*    introduction;
@property (retain) NSString*    thumbnail;
@property (retain) Media*       media;
@property (retain) NSArray<Media*> *photos;
@property (retain) NSArray<User*> *likes;
@property GenderType            gender;
@property BOOL                  simulated;

@property NSUInteger credits;
@property (readonly) NSUInteger initialFreeCredits;
@property (readonly) NSUInteger openChatCredits;

- (id)dictionary;


+ (User*)me;
- (BOOL)isMe;
+ (NSArray*) ageGroups;
+ (NSArray*) introductions;

// Gender related
- (void)        setGenderTypeFromString:(NSString*)gender;
- (void)        setGenderTypeFromCode:(NSString *)genderCode;
- (NSString*)   genderTypeString;
- (NSString*)   genderCode;
- (UIColor*)    genderColor;
+ (NSArray*)    genders;
+ (NSArray*)    genderCodes;
- (BOOL)        likes:(User*)user;
- (void)        like:(User*)user;
- (void)        unlike:(User*)user;
+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(AnyBlock)actionBlock;

@end




