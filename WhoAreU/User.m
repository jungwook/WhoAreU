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
#import "NSData+GZIP.h"

#pragma mark History


@implementation NSDictionary (compress)

- (NSData *)compressDictionary
{
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    NSData *compressed = [data gzippedDataWithCompressionLevel:1.0];
    NSLog(@"COMPRESSED:%ld->%ld", data.length, compressed.length);

    if (error) {
        NSLog(@"ERROR:Error compressing dictionary - %@", error.localizedDescription);
        return nil;
    }
    return compressed;
}

@end

@implementation NSData (dictionary)

- (id)uncompressDictionary
{
    NSError *error = nil;
    NSData *uncompressed = [self gunzippedData];
    
    id dic = [NSPropertyListSerialization propertyListWithData:uncompressed options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];
    
    NSLog(@"UNCOMPRESS:%ld->%ld", self.length, uncompressed.length);
    
    if (error) {
        NSLog(@"ERROR:Error uncompressing dictionary - %@", error.localizedDescription);
        return nil;
    }
    
    return dic;
}

@end

@implementation History
@dynamic user, channel, messageId;

+ (NSString *)parseClassName
{
    return @"History";
}

+ (instancetype)historyWithChannelId:(id)channelId
                           messageId:(id)messageId
{
    History *history = [History new];
    history.channel = [Channel objectWithoutDataWithObjectId:channelId];
    history.user = [User me];
    history.messageId = messageId;
    return history;
}

@end

#pragma mark Message

@implementation Message
@dynamic fromUser, channel, message, media, type, read;

+ (NSString *)parseClassName {
    return @"Message";
}

+ (instancetype)message:(id)object
              channelId:(id)channelId
                  count:(NSUInteger)userCount
{
    Message *message = [Message new];
    message.fromUser = [User me];
    message.channel = [Channel objectWithoutDataWithObjectId:channelId];
    message.read = userCount;

    if ([object isKindOfClass:[NSString class]]) {
        message.message = [object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        message.type = kMessageTypeText;
        
        return message;
    }
    else if ([object isKindOfClass:[Media class]]) {
        message.media = object;
        message.type = kMessageTypeMedia;
        message.message = (message.type == kMediaTypePhoto) ? @"new photo message" : @"new video message";
        
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
    message.read = users.count;
    if ([object isKindOfClass:[NSString class]]) {
        message.message = object;
        message.type = kMessageTypeText;
        
        return message;
    }
    else if ([object isKindOfClass:[Media class]]) {
        message.media = object;
        message.type = kMessageTypeMedia;
        message.message = (message.type == kMediaTypePhoto) ? @"new photo message" : @"new video message";
        
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
        dictionary[fObjectId] = self.objectId;
    if (self.createdAt)
        dictionary[fCreatedAt] = self.createdAt;
    if (self.updatedAt)
        dictionary[fUpdatedAt] = self.updatedAt;
    
    if (self.dataAvailable) {
        if (self.fromUser)
            dictionary[fFromUser] = self.fromUser.simpleDictionary;
        if (self.channel)
            dictionary[fChannel] = self.channel.dictionary;
        if (self.message)
            dictionary[fMessage] = self.message;
        if (self.media)
            dictionary[fMedia] = self.media.dictionary;
        dictionary[@"type"] = @(self.type);
        dictionary[@"read"] = @(self.read);
    }
    else {
        NSLog(@"WARNING[%s] %@ %@ DIRTY", __func__, NSStringFromClass([self class]), self.objectId);
    }
    
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
        dictionary[fObjectId] = self.objectId;
    if (self.createdAt)
        dictionary[fCreatedAt] = self.createdAt;
    if (self.updatedAt)
        dictionary[fUpdatedAt] = self.updatedAt;
    
    if (self.dataAvailable) {
        if (self.userId)
            dictionary[@"userId"] = self.userId;
        if (self.comment)
            dictionary[@"comment"] = self.comment;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.media)
            dictionary[fMedia] = self.media;
        
        dictionary[@"type"] = @(self.type);
        dictionary[@"source"] = @(self.source);
        dictionary[@"size"] = NSStringFromCGSize(self.size);
    }
    else {
        NSLog(@"WARNING[%s] %@ %@ DIRTY", __func__, NSStringFromClass([self class]), self.objectId);
    }
    
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
@dynamic nickname, where, whereUpdatedAt, age, desc, introduction, thumbnail, media, photos, likes, gender, simulated, credits;

+ (User *)me
{
    return [User currentUser];
}

+ (BOOL)meEquals:(id)userId
{
    return [[User me].objectId isEqualToString:userId];
}

- (id)simpleDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[fObjectId] = self.objectId;
    if (self.createdAt)
        dictionary[fCreatedAt] = self.createdAt;
    if (self.updatedAt)
        dictionary[fUpdatedAt] = self.updatedAt;
    
    if (self.dataAvailable) {
        if (self.nickname)
            dictionary[fNickname] = self.nickname;
        if (self.whereUpdatedAt)
            dictionary[fWhereUpdatedAt] = self.whereUpdatedAt;
        if (self.age)
            dictionary[fAge] = self.age;
        if (self.desc)
            dictionary[fDesc] = self.desc;
        if (self.introduction)
            dictionary[fIntroduction] = self.introduction;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.where)
            dictionary[fWhere] = NSStringFromCGSize(CGSizeMake(self.where.latitude, self.where.longitude));
    }
    else {
        NSLog(@"WARNING[%s] %@ %@ DIRTY", __func__, NSStringFromClass([self class]), self.objectId);
    }
    
    return dictionary;
}

- (id)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        dictionary[fObjectId] = self.objectId;
    if (self.createdAt)
        dictionary[fCreatedAt] = self.createdAt;
    if (self.updatedAt)
        dictionary[fUpdatedAt] = self.updatedAt;
    
    if (self.dataAvailable) {
        if (self.nickname)
            dictionary[fNickname] = self.nickname;
        if (self.whereUpdatedAt)
            dictionary[fWhereUpdatedAt] = self.whereUpdatedAt;
        if (self.age)
            dictionary[fAge] = self.age;
        if (self.desc)
            dictionary[fDesc] = self.desc;
        if (self.introduction)
            dictionary[fIntroduction] = self.introduction;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.media)
            dictionary[fMedia] = self.media.dictionary;
        if (self.where)
            dictionary[fWhere] = NSStringFromCGSize(CGSizeMake(self.where.latitude, self.where.longitude));
        
        NSMutableArray *photos = [NSMutableArray array];
        for (Media *photo in self.photos) {
            [photos addObject:photo.objectId];
        }
        dictionary[fPhotos] = photos;
        
        NSMutableArray *likes = [NSMutableArray array];
        for (User *like in self.likes) {
            [likes addObject:like.objectId];
        }
        dictionary[fLikes] = likes;
    }
    else {
        NSLog(@"WARNING[%s] %@ %@ DIRTY", __func__, NSStringFromClass([self class]), self.objectId);
    }

    return dictionary;
}

- (void)like:(User *)user
{
    BOOL likes = [self likes:user];
    if (!likes) {
        [self addUniqueObject:user forKey:fLikes];
        [self saveInBackground];
    }
}

- (void)unlike:(User *)user
{
    BOOL likes = [self likes:user];
    if (likes) {
        [self removeObjectsInArray:@[user] forKey:fLikes];
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

- (BOOL) isMe
{
    return [User meEquals:self.objectId];
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
        [self setObject:media forKey:fMedia];
        self.thumbnail = media.thumbnail;
    }
    else {
        NSLog(@"Removing media and thumbnail");
        [self removeObjectForKey:fMedia];
        [self removeObjectForKey:fThumbnail];
    }
}

+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(AnyBlock)actionBlock
{
    User *me = [User me];

    id channelId = [MessageCenter channelIdForUser:user];
    if (channelId) {
        NSLog(@"ChannelId:%@", channelId);
        [Channel fetch:channelId completion:^(Channel *channel) {
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
        [self addUniqueObjectsFromArray:[users arrayByAddingObject:[User me]] forKey:fUsers];
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
        dictionary[fObjectId] = self.objectId;
    if (self.createdAt)
        dictionary[fCreatedAt] = self.createdAt;
    if (self.updatedAt)
        dictionary[fUpdatedAt] = self.updatedAt;
    
    if (self.dataAvailable) {
        if (self.name)
            dictionary[@"name"] = self.name;
        if (self.createdBy)
            dictionary[fCreatedBy] = self.createdBy.objectId;
        
        if (self.users) {
            NSMutableArray *users = [NSMutableArray array];
            for (User *user in self.users) {
                NSMutableDictionary *simpleUser = [NSMutableDictionary new];
                if (user.objectId) {
                    [simpleUser setObject:user.objectId forKey:fObjectId];
                }
                if (user.nickname) {
                    [simpleUser setObject:user.nickname forKey:fNickname];
                }
                if (user.thumbnail) {
                    [simpleUser setObject:user.thumbnail forKey:fThumbnail];
                }
                [users addObject:simpleUser];
            }
            dictionary[fUsers] = users;
        }
    }
    else {
        NSLog(@"WARNING[%s] %@ %@ DIRTY", __func__, NSStringFromClass([self class]), self.objectId);
    }
    
    return dictionary;
}

- (void) removeUsers:(NSArray<User*>*)users completion:(VoidBlock)action
{
    [self removeObjectsInArray:users forKey:fUsers];
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

+ (void)fetch:(id)channelId completion:(ChannelBlock)handler
{
    Channel *channel = [Channel objectWithoutDataWithObjectId:channelId];
    [channel fetched:^{
        handler(channel);
    }];
}

- (void)fetched:(VoidBlock)handler
{
    Counter *counter = [Counter new];
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        } else {
            id counterId = [counter setCount:self.users.count completion:^{
                handler();
            }];
            [self.users enumerateObjectsUsingBlock:^(User * _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
                [user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (!error) {
                        [counter decreaseCount:counterId];
                    }
                    else {
                        NSLog(@"ERROR[%s]:%@", __func__, error.localizedDescription);
                    }
                }];
            }];
        }
    }];
}

- (void) removeUser:(User*)user completion:(VoidBlock)action
{
    [self removeUsers:@[user] completion:action];
}

- (void) addUsers:(NSArray<User*>*)users completion:(VoidBlock)action
{
    [self addUniqueObjectsFromArray:users forKey:fUsers];
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
