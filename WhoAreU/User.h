//
//  User.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Parse/Parse.h>

typedef void(^BOOLBlock)(BOOL value);
typedef void(^VoidBlock)(void);
typedef void(^ImageBlock)(UIImage* image);
typedef void(^ArrayBlock)(NSArray* array);
typedef void(^StringBlock)(NSString* string);

@class User;
@class MessageItem;
@class Media;

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

@interface Message : PFObject <PFSubclassing>
@property (retain) User *fromUser;
@property (retain) User *toUser;
@property (retain) NSString* text;
@property (retain) Media* media;
@property MessageType type;
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
@end

#pragma mark User

@interface User : PFUser <PFSubclassing>
@property (retain) NSString*    nickname;
@property (retain) PFGeoPoint*  where;
@property (retain) NSDate*      whereUdatedAt;
@property (retain) NSString*    age;
@property (retain) NSString*    desc;
@property (retain) Media*       media;
@property (retain) NSArray<Media*> *photos;
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


@end

@interface SimulatedUsers : NSObject
+ (void) createUsers;
+ (void) resetUsers;
@end



