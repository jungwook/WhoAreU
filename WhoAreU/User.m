//
//  User.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "User.h"
#import "S3File.h"
#import "BaseFunctions.h"
#import "MessageCenter.h"

#pragma mark Message

//@implementation NSMutableDictionary(Dictionary)
//
//- (void)setObjectId:(NSString *)objectId
//{
//    if (objectId) {
//        [self setObject:objectId forKey:@"objectId"];
//    }
//}
//
//- (NSString *)objectId
//{
//    return [self objectForKey:@"objectId"];
//}
//
//- (NSDate *)createdAt
//{
//    return [self objectForKey:@"createdAt"];
//}
//
//- (void)setCreatedAt:(NSDate *)createdAt
//{
//    if (createdAt) {
//        [self setObject:createdAt forKey:@"createdAt"];
//    }
//}
//
//- (NSDate *)updatedAt
//{
//    return [self objectForKey:@"updatedAt"];
//}
//
//- (void)setUpdatedAt:(NSDate *)updatedAt
//{
//    if (updatedAt) {
//        [self setObject:updatedAt forKey:@"updatedAt"];
//    }
//}
//
//- (NSString *)fromUserId
//{
//    return [self objectForKey:@"fromUserId"];
//}
//
//- (void)setFromUserId:(NSString *)fromUserId
//{
//    if (fromUserId) {
//        [self setObject:fromUserId forKey:@"fromUserId"];
//    }
//}
//
//- (NSString *)channelId
//{
//    return [self objectForKey:@"channelId"];
//}
//
//- (void)setChannelId:(NSString *)channelId
//{
//    if (channelId) {
//        [self setObject:channelId forKey:@"channelId"];
//    }
//}
//
//- (NSString *)toUserId
//{
//    return [self objectForKey:@"toUserId"];
//}
//
//-(void)setToUserId:(NSString *)toUserId
//{
//    if (toUserId) {
//        [self setObject:toUserId forKey:@"toUserId"];
//    }
//}
//
//- (NSString *)message
//{
//    return [self objectForKey:@"message"];
//}
//
//- (void)setMessage:(NSString *)message
//{
//    if (message) {
//        [self setObject:message forKey:@"message"];
//    }
//}
//
//- (MediaDic *)media
//{
//    return [self objectForKey:@"media"];
//}
//
//- (void)setMedia:(MediaDic *)media
//{
//    if (media) {
//        [self setObject:media forKey:@"media"];
//    }
//}
//
//- (MessageType)messageType
//{
//    return [[self objectForKey:@"messageType"] integerValue];
//}
//
//- (void)setMessageType:(MessageType)messageType
//{
//    [self setObject:@(messageType) forKey:@"messageType"];
//}
//
//- (BOOL)read
//{
//    return [[self objectForKey:@"read"] integerValue];
//}
//
//- (void)setRead:(BOOL)read
//{
//    [self setObject:@(read) forKey:@"read"];
//}
//
//- (NSString *)userId
//{
//    return [self objectForKey:@"userId"];
//}
//
//- (void)setUserId:(NSString *)userId
//{
//    if (userId)
//        [self setObject:userId forKey:@"userId"];
//}
//
//- (NSString *)comment
//{
//    return [self objectForKey:@"comment"];
//}
//
//- (void)setComment:(NSString *)comment
//{
//    if (comment)
//        [self setObject:comment forKey:@"comment"];
//}
//
//- (NSString *)thumbnail
//{
//    return [self objectForKey:@"thumbnail"];
//}
//
//- (void)setThumbnail:(NSString *)thumbnail
//{
//    if (thumbnail)
//        [self setObject:thumbnail forKey:@"thumbnail"];
//}
//
//- (NSString *)mediaFile
//{
//    return [self objectForKey:@"mediaFile"];
//}
//
//- (void)setMediaFile:(NSString *)media
//{
//    if (media)
//        [self setObject:media forKey:@"mediaFile"];
//}
//
//- (MediaType)mediaType
//{
//    return [[self objectForKey:@"mediaType"] integerValue];
//}
//
//- (void)setMediaType:(MediaType)type
//{
//    [self setObject:@(type) forKey:@"mediaType"];
//}
//
//- (BOOL)sync
//{
//    return [[self objectForKey:@"sync"] boolValue];
//}
//
//- (void)setSync:(BOOL)sync
//{
//    [self setObject:@(sync) forKey:@"sync"];
//}
//
//- (BOOL)source
//{
//    return [[self objectForKey:@"source"] boolValue];
//}
//
//-(void)setSource:(BOOL)source
//{
//    [self setObject:@(source) forKey:@"source"];
//}
//
//- (CGSize)size
//{
//    return CGSizeFromString([self objectForKey:@"size"]);
//}
//
//- (void)setSize:(CGSize)size
//{
//    [self setObject:NSStringFromCGSize(size) forKey:@"size"];
//}
//
//@end

@implementation Message
@dynamic fromUser, channel, message, media, type, read;

+ (NSString *)parseClassName {
    return @"Message";
}

+ (instancetype)message:(id)object
                channel:(Channel*)channel
{
    Message *message = [Message new];
    message.fromUser = [User me];
    message.channel = channel;
    if ([object isKindOfClass:[NSString class]]) {
        message.message = [object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        message.type = kMessageTypeText;
        message.read = NO;
        
        return message;
    }
    else if ([object isKindOfClass:[Media class]]) {
        message.media = object;
        message.type = kMessageTypeMedia;
        message.message = (message.type == kMediaTypePhoto) ? @"new photo message" : @"new video message";
        message.read = NO;
        
        return message;
    }
    else {
        return nil;
    }
}

NSString* __usernames(NSArray*users)
{
    NSMutableArray *nicknames = [NSMutableArray array];
    for (User *user in users) {
        [nicknames addObject:user.nickname];
    }
    return [nicknames componentsJoinedByString:@", "];
}

+ (instancetype)message:(id)object users:(NSArray*)users
{
    Channel *channel = [Channel newWithUsers:users];
    
    Message *message = [Message new];
    message.fromUser = [User me];
    message.channel = channel;
    if ([object isKindOfClass:[NSString class]]) {
        message.message = object;
        message.type = kMessageTypeText;
        message.read = NO;
        
        return message;
    }
    else if ([object isKindOfClass:[Media class]]) {
        message.media = object;
        message.type = kMessageTypeMedia;
        message.message = (message.type == kMediaTypePhoto) ? @"new photo message" : @"new video message";
        message.read = NO;
        
        return message;
    }
    else {
        return nil;
    }
}

- (id)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[@"objectId"] = self.objectId;
    if (self.createdAt)
        dictionary[@"createdAt"] = self.createdAt;
    if (self.updatedAt)
        dictionary[@"updatedAt"] = self.updatedAt;
    
    if (self.fromUser)
        dictionary[@"fromUser"] = self.fromUser.dictionary;
    if (self.channel)
        dictionary[@"channel"] = self.channel.dictionary;
    if (self.message)
        dictionary[@"message"] = self.message;
    if (self.media)
        dictionary[@"media"] = self.media.dictionary;
    dictionary[@"type"] = @(self.type);
    dictionary[@"read"] = @(self.read);
    
    return dictionary;
}

@end

#pragma mark Media

@implementation Media
@dynamic userId, comment, type, thumbnail, media, size, source;

+ (NSString *)parseClassName {
    return @"Media";
}

- (id)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[@"objectId"] = self.objectId;
    if (self.createdAt)
        dictionary[@"createdAt"] = self.createdAt;
    if (self.updatedAt)
        dictionary[@"updatedAt"] = self.updatedAt;
    
    if (self.userId)
        dictionary[@"userId"] = self.userId;
    if (self.comment)
        dictionary[@"comment"] = self.comment;
    if (self.thumbnail)
        dictionary[@"thumbnail"] = self.thumbnail;
    if (self.media)
        dictionary[@"media"] = self.media;
    
    dictionary[@"type"] = @(self.type);
    dictionary[@"source"] = @(self.source);
    dictionary[@"size"] = NSStringFromCGSize(self.size);
    
    return dictionary;
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
@dynamic nickname, where, whereUdatedAt, age, desc, introduction, thumbnail, media, photos, likes, gender, simulated, credits;

+ (User *)me
{
    return [User currentUser];
}

- (id)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[@"objectId"] = self.objectId;
    if (self.createdAt)
        dictionary[@"createdAt"] = self.createdAt;
    if (self.updatedAt)
        dictionary[@"updatedAt"] = self.updatedAt;
    
    if (self.nickname)
        dictionary[@"nickname"] = self.nickname;
    if (self.whereUdatedAt)
        dictionary[@"whereUdatedAt"] = self.whereUdatedAt;
    if (self.age)
        dictionary[@"age"] = self.age;
    if (self.desc)
        dictionary[@"desc"] = self.desc;
    if (self.introduction)
        dictionary[@"introduction"] = self.introduction;
    if (self.thumbnail)
        dictionary[@"thumbnail"] = self.thumbnail;
    if (self.media)
        dictionary[@"media"] = self.media.dictionary;
    if (self.where)
        dictionary[@"where"] = NSStringFromCGSize(CGSizeMake(self.where.latitude, self.where.longitude));
    
    NSMutableArray *photos = [NSMutableArray array];
    for (Media *photo in self.photos) {
        [photos addObject:photo.objectId];
    }
    dictionary[@"photos"] = photos;

    NSMutableArray *likes = [NSMutableArray array];
    for (User *like in self.likes) {
        [likes addObject:like.objectId];
    }
    dictionary[@"likes"] = likes;
    
    return dictionary;
}

- (void)like:(User *)user
{
    BOOL likes = [self likes:user];
    if (!likes) {
        [self addUniqueObject:user forKey:@"likes"];
        [self saveInBackground];
    }
}

- (void)unlike:(User *)user
{
    BOOL likes = [self likes:user];
    if (likes) {
        [self removeObjectsInArray:@[user] forKey:@"likes"];
        [self saveInBackground];
    }
}

- (BOOL)likes:(User *)user
{
    return [self.likes containsObject:user];
}

- (NSUInteger)initialFreeCredits
{
    return 1000;
}

- (NSUInteger)openChatCredits
{
    return 25;
}

- (NSString*) genderCode
{
    switch (self.gender) {
        case kGenderTypeMale:
            return @"M";
        case kGenderTypeFemale:
            return @"F";
        case kGenderTypeUnknown:
            return @"??";
    }
}

- (UIColor*) genderColor
{
    switch (self.gender) {
        case kGenderTypeMale:
            return [UIColor colorWithRed:95/255.f green:167/255.f blue:229/255.f alpha:1.0f];
        case kGenderTypeFemale:
            return [UIColor colorWithRed:240/255.f green:82/255.f blue:10/255.f alpha:1.0f];
        case kGenderTypeUnknown:
            return [UIColor colorWithRed:128/255.f green:128/255.f blue:128/255.f alpha:1.0f];
    }
}

- (NSString *)genderTypeString
{
    switch (self.gender) {
        case kGenderTypeMale:
            return @"Male";
        case kGenderTypeFemale:
            return @"Female";
        case kGenderTypeUnknown:
            return @"Unknown";
    }
}

- (void)setGenderTypeFromCode:(NSString *)genderCode
{
    if ([genderCode isEqualToString:@"M"]) {
        self.gender = kGenderTypeMale;
    }
    else if ([genderCode isEqualToString:@"F"]) {
        self.gender = kGenderTypeFemale;
    }
    else {
        self.gender = kGenderTypeUnknown;
    }
}

- (void)setGenderTypeFromString:(NSString *)gender
{
    id info = [User genderInfo];
    
    NSNumber *ret = info[gender];
    if (ret) {
        self.gender = [ret integerValue];
    }
    else {
        self.gender = kGenderTypeUnknown;
    }
}

+ (NSDictionary*) genderInfo
{
    return @{
             @"Male" : @(kGenderTypeMale),
             @"Female" : @(kGenderTypeFemale),
             };
}

+ (NSArray *)genderCodes
{
    return @[
             @"M",
             @"F",
             ];
}

+ (NSArray *)genders
{
    return @[
             @"Male",
             @"Female",
             ];
}

- (BOOL)isMe
{
    return ([self.objectId isEqualToString:[User me].objectId]);
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

-(void)setMedia:(Media *)media
{
    if (media) {
        [self setObject:media forKey:@"media"];
        self.thumbnail = media.thumbnail;
    }
    else {
        NSLog(@"Removing media and thumbnail");
        [self removeObjectForKey:@"media"];
        [self removeObjectForKey:@"thumbnail"];
    }
}

+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(AnyBlock)actionBlock
{
    User *me = [User me];

    id channelId = [MessageCenter channelIdForUser:user];
    if (channelId) {
        NSLog(@"ChannelId:%@", channelId);
        Channel *channel = [Channel objectWithoutDataWithObjectId:channelId];
        [channel fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (actionBlock) {
                actionBlock(channel);
            }
        }];
        return;
    }
    
    BOOL enoughCredits = me.credits > me.openChatCredits;
    
    NSString *message = enoughCredits ?  [NSString stringWithFormat:@"You have a total of %ld credits.\nTo continue %ld credits will be charged. Send your first hello message to proceed.", me.credits, me.openChatCredits] : [NSString stringWithFormat:@"You need %ld credits to open a new chat!\n\nYou currently have a total of %ld credits. Would you like to buy more credits?", me.openChatCredits, me.credits];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Initiate Chat" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    void(^buyhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        NSLog(@"Buy more credits");
        
        UIViewController *vc = [viewController.storyboard instantiateViewControllerWithIdentifier:@"Credits"];
        
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        [viewController presentViewController:vc animated:YES completion:nil];
    };
    void(^okhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        me.credits -= me.openChatCredits;
        [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSString *message = alert.textFields.firstObject.text;
                if (actionBlock) {
                    actionBlock([message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
                }
            }
        }];
    };
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:enoughCredits ? okhandler : buyhandler];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
    
    if (enoughCredits) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            
        }];
    }
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end

@implementation Channel
@dynamic users, name, createdBy;

+ (instancetype) newWithUsers:(NSArray*)users
{
    return [[Channel alloc] initWithUsers:users];
}

- (instancetype)initWithUsers:(NSArray*)users
{
    self = [super init];
    if (self) {
        self.name = __usernames(users);
        self.createdBy = [User me];
        [self addUniqueObjectsFromArray:[users arrayByAddingObject:[User me]] forKey:@"users"];
    }
    return self;
}

+ (NSString *)parseClassName
{
    return @"Channel";
}

- (id)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[@"objectId"] = self.objectId;
    if (self.createdAt)
        dictionary[@"createdAt"] = self.createdAt;
    if (self.updatedAt)
        dictionary[@"updatedAt"] = self.updatedAt;
    
    if (self.name)
        dictionary[@"name"] = self.name;
    if (self.createdBy)
        dictionary[@"createdBy"] = self.createdBy.dictionary;
    
    if (self.users) {
        NSMutableArray *users = [NSMutableArray array];
        for (User *user in self.users) {
            [users addObject:user.objectId];
        }
        dictionary[@"users"] = users;
    }
    
    return dictionary;
}

- (void) removeUsers:(NSArray<User*>*)users completion:(VoidBlock)action
{
    [self removeObjectsInArray:users forKey:@"users"];
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded && !error) {
            if (action) {
                action();
            }
        }
        else {
            NSLog(@"ERROR:[%s]%@", __func__, error.localizedDescription);
        }
    }];
}

- (void) removeUser:(User*)user completion:(VoidBlock)action
{
    [self removeUsers:@[user] completion:action];
}

- (void) addUsers:(NSArray<User*>*)users completion:(VoidBlock)action
{
    [self addUniqueObjectsFromArray:users forKey:@"users"];
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded && !error) {
            if (action) {
                action();
            }
        }
        else {
            NSLog(@"ERROR:[%s]%@", __func__, error.localizedDescription);
        }
    }];
}

@end
