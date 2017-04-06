//
//  User.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "User.h"
#import "S3File.h"

#pragma mark Media

@implementation Media
@dynamic userId, comment, type, thumbnail, media, size, source;

+ (NSString *)parseClassName {
    return @"Media";
}

- (void)setSize:(CGSize)mediaSize
{
    [self setObject:@(mediaSize.width) forKey:@"width"];
    [self setObject:@(mediaSize.height) forKey:@"height"];
}

- (CGSize)size
{
    return CGSizeMake([[self objectForKey:@"width"] floatValue], [[self objectForKey:@"height"] floatValue]);
}

- (void)imageLoaded:(ImageBlock)block
{
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [S3File getDataFromFile:self.media completedBlock:^(NSData *data, NSError *error, BOOL fromCache) {
            if (block) {
                block([UIImage imageWithData:data]);
            }
        }];
    }];
}

- (void)thumbnailLoaded:(ImageBlock)block
{
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [S3File getDataFromFile:self.thumbnail completedBlock:^(NSData *data, NSError *error, BOOL fromCache) {
            if (block) {
                block([UIImage imageWithData:data]);
            }
        }];
    }];
}

- (void)fetched:(VoidBlock)handler
{
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        } else {
            handler();
        }
    }];
}

- (void)saved:(VoidBlock)handler
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
        else {
            if (handler) {
                handler();
            }
        }
    }];
}
@end


#pragma mark user

@implementation User
@dynamic nickname, where, whereUdatedAt, age, desc, media, gender;

+ (User *)me
{
    return [User currentUser];
}

+ (NSArray *)genders
{
    return @[
             @"Male",
             @"Female",
             ];
}

+ (NSArray*) ageGroups
{
    return @[
             @"Child",
             @"20s",
             @"30s",
             @"40s",
             @"Senior",
             ];
}

+ (NSArray*) introductions
{
    return @[
             @"Meet",
             @"Flirt",
             @"Vacation",
             @"Drive",
             @"Ride",
             @"Chat",
             @"Drink",
             @"Lunch",
             @"Dinner",
             @"Picknick",
             @"Work",
             @"Watch a movie",
             @"Make Love",
             ];
}

@end
