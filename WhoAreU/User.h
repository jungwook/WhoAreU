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

typedef void(^BOOLBlock)(BOOL value);
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


typedef NSMutableDictionary MessageDic;
typedef NSMutableDictionary MediaDic;

@interface NSMutableDictionary(Dictionary)
@property (nonatomic, assign) NSString* objectId;
@property (nonatomic, assign) NSDate*   createdAt;
@property (nonatomic, assign) NSDate*   updatedAt;
@property (nonatomic, assign) NSString* userId;
@property (nonatomic, assign) NSString* comment;
@property (nonatomic, assign) NSString* thumbnail;
@property (nonatomic, assign) NSString* mediaFile;
@property MediaType mediaType;
@property CGSize size;
@property BOOL source;

@property (nonatomic, assign) NSString* fromUserId;
@property (nonatomic, assign) NSString* toUserId;
@property (nonatomic, assign) NSString* message;
@property (nonatomic, assign) MediaDic*    media;
@property MessageType messageType;
@property BOOL read;

@end

@interface Message : PFObject <PFSubclassing>
@property (retain) User *fromUser;
@property (retain) User *toUser;
@property (retain) NSString* message;
@property (retain) Media* media;
@property MessageType type;
@property BOOL read;
- (MessageDic*) dictionary;
+ (instancetype) message:(NSString *)text toUser:(User*)user;
+ (instancetype) media:(Media *)media toUser:(User*)user;
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

- (void) fetched:(VoidBlock)handler;
- (void) saved:(VoidBlock)handler;
- (void) imageLoaded:(ImageBlock)block;
- (void) thumbnailLoaded:(ImageBlock)block;

-(MediaDic*) dictionary;
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
@end

@interface SimulatedUsers : NSObject
+ (void) createUsers;
+ (void) resetUsers;
@end



