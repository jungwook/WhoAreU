//
//  User.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Parse/Parse.h>

typedef NS_OPTIONS(NSUInteger, GenderType)
{
    kGenderTypeMale = 0,
    kGenderTypeFemale,
};

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
