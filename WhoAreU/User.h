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

typedef NS_OPTIONS(NSUInteger, GenderType)
{
    kGenderTypeMale = 0,
    kGenderTypeFemale,
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

@interface User : PFUser <PFSubclassing>
@property (retain) NSString*    nickname;
@property (retain) PFGeoPoint*  where;
@property (retain) NSDate*      whereUdatedAt;
@property (retain) NSString*    age;
@property (retain) NSString*    desc;
@property (retain) NSArray*     media;
@property GenderType            gender;

+ (User*)me;
+ (NSArray *)genders;
+ (NSArray*) ageGroups;
+ (NSArray*) introductions;

@end


