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
#import "MediaPicker.h"

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
    message.read = userCount - 1; // minus myself..

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
    return [nicknames componentsJoinedByString:kStringCommaSpace];
}

+ (instancetype)message:(id)object users:(NSArray*)users
{
    Channel *channel = [Channel newWithUsers:users];
    
    Message *message = [Message new];
    message.fromUser = [User me];
    message.channel = channel;
    message.read = users.count - 1; // minus myself..
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
        dictionary[fType] = @(self.type);
        dictionary[fRead] = @(self.read);
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
            dictionary[fUserId] = self.userId;
        if (self.comment)
            dictionary[fComment] = self.comment;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.media)
            dictionary[fMedia] = self.media;
        
        dictionary[fType] = @(self.type);
        dictionary[fSource] = @(self.source);
        dictionary[fSize] = NSStringFromCGSize(self.size);
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
@dynamic nickname, where, age, channel, introduction, thumbnail, media, photos, likes, gender, simulated, credits;

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

    if (self.dataAvailable) {
        if (self.nickname)
            dictionary[fNickname] = self.nickname;
        if (self.age)
            dictionary[fAge] = self.age;
        if (self.channel)
            dictionary[fChannel] = self.channel;
        if (self.introduction)
            dictionary[fIntroduction] = self.introduction;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.where) {
            dictionary[fLatitude] = @(self.where.latitude);
            dictionary[fLongitude] = @(self.where.longitude);
        }
        dictionary[fGender] = self.genderTypeString;
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
        if (self.age)
            dictionary[fAge] = self.age;
        if (self.channel)
            dictionary[fChannel] = self.channel;
        if (self.introduction)
            dictionary[fIntroduction] = self.introduction;
        if (self.thumbnail)
            dictionary[fThumbnail] = self.thumbnail;
        if (self.media)
            dictionary[fMedia] = self.media.dictionary;
        if (self.where)
            dictionary[fWhere] = NSStringFromCGSize(CGSizeMake(self.where.latitude, self.where.longitude));
        
        dictionary[fGender] = self.genderTypeString;
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

- (void)setChannel:(NSString *)channel
{
    [self setObject:channel forKey:fChannel];
    [MessageCenter subscribeToUserChannel:channel];
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
            return [UIColor maleColor];
        case kGenderTypeFemale:
            return [UIColor femaleColor];
        case kGenderTypeUnknown:
            return [UIColor unknownGenderColor];
    }
}

+ (UIColor*) genderColorFromTypeString:(id)typeString
{
    if ([typeString isEqualToString:@"Male"]) {
        return [UIColor maleColor];
    }
    else if ([typeString isEqualToString:@"Female"]) {
        return [UIColor femaleColor];
    }
    else {
        return [UIColor unknownGenderColor];
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
             @"10s",
             @"20s",
             @"30s",
             @"40s",
             @"50s",
             ];
}

+ (NSArray*) channels
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
        if (media.dataAvailable) {
            self.thumbnail = media.thumbnail;
        }
    }
    else {
        [self removeObjectForKey:fMedia];
        [self removeObjectForKey:fThumbnail];
    }
}

+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(AnyBlock)actionBlock
{
    User *me = [User me];

    id channelId = [MessageCenter lastJoinedChannelIdForUser:user];
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
                message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (message.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:message forKey:@"LastFirstMessage"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                if (actionBlock) {
                    actionBlock(message);
                }
            }
        }];
    };
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:enoughCredits ? okhandler : buyhandler];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
    
    if (enoughCredits) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.font = [UIFont systemFontOfSize:17];
            textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastFirstMessage"];
        }];
    }
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)payForChatWithChannelOnViewController:(UIViewController *)viewController action:(AnyBlock)actionBlock
{
    User *me = [User me];
    
    BOOL enoughCredits = me.credits > me.openChatCredits;
    
    NSString *message = enoughCredits ?  [NSString stringWithFormat:@"\nYou have a total of %ld credits.\nTo continue %ld credits will be charged.\n\nSay Hi to friends in this channel(%@).", me.credits, me.openChatCredits, me.channel] : [NSString stringWithFormat:@"\nYou need %ld credits to send a message to this channel (%@)!\n\nYou currently have a total of %ld credits. Would you like to buy more credits?", me.openChatCredits, me.channel, me.credits];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Say Hi!" message:message preferredStyle:UIAlertControllerStyleAlert];
    
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
                message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (message.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:message forKey:@"LastFirstMessage"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                if (actionBlock) {
                    id ret = @{
                               fMessage : message,
                               fType : @(kMessageTypeText),
                               };
                    actionBlock(ret);
                }
            }
        }];
    };
    
    void(^mediaHandler)(UIAlertAction * _Nonnull action) =  ^(UIAlertAction * _Nonnull action) {
        [MediaPicker pickMediaOnViewController:viewController withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                NSString *message = alert.textFields.firstObject.text;
                message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (actionBlock) {
                    id ret = @{
                               fMessage : message,
                               fType : @(kMessageTypeMedia),
                               fMedia : media.dictionary
                               };
                    actionBlock(ret);
                }
            }
        }];
    };
    
    __unused UIAlertAction *mediaAction = [UIAlertAction actionWithTitle:@"photo" style:UIAlertActionStyleDefault handler:mediaHandler];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:enoughCredits ? okhandler : buyhandler];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
    
    if (enoughCredits) {
//        [alert addAction:mediaAction];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastFirstMessage"];
        }];
        [alert addAction:okAction];
    }
    
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
            dictionary[fName] = self.name;
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
                if (user.channel) {
                    [simpleUser setObject:user.channel forKey:fChannel];
                }
                [simpleUser setObject:user.genderTypeString forKey:fGender];
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
