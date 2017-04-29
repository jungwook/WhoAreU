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

#pragma mark Message

@implementation Installation
@dynamic user, credits, initialFreeCredits, openChatCredits;

- (NSUInteger)initialFreeCredits
{
    return 1000;
}

- (NSUInteger)openChatCredits
{
    return 250;
}

+ (void)payForChatOnViewController:(UIViewController *)viewController action:(VoidBlock)actionBlock
{
    Installation *install = [Installation currentInstallation];
    
    void(^buyhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        NSLog(@"Buy more credits");
        
        UIViewController *vc = [viewController.storyboard instantiateViewControllerWithIdentifier:@"Credits"];
        // other vc initializations;
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        [viewController presentViewController:vc animated:YES completion:nil];
    };
    void(^okhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        
        install.credits -= install.openChatCredits;
        [install saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                if (actionBlock) {
                    actionBlock();
                    // Example ... [self performSegueWithIdentifier:@"Chat" sender:user];
                }
            }
        }];
    };
    BOOL enoughCredits = install.credits > install.openChatCredits;
    
    NSString *message = enoughCredits ?  [NSString stringWithFormat:@"You have a total of %ld credits.\nTo continue %ld credits will be charged. Do you want to continue?", install.credits, install.openChatCredits] : [NSString stringWithFormat:@"You need %ld credits to open a new chat!\n\nYou currently have a total of %ld credits. Would you like to buy more credits?", install.openChatCredits, install.credits];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:enoughCredits ? okhandler : buyhandler];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Initiate Chat" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end


@implementation NSMutableDictionary(Dictionary)

- (void)setObjectId:(NSString *)objectId
{
    if (objectId) {
        [self setObject:objectId forKey:@"objectId"];
    }
}

- (NSString *)objectId
{
    return [self objectForKey:@"objectId"];
}

- (NSDate *)createdAt
{
    return [self objectForKey:@"createdAt"];
}

- (void)setCreatedAt:(NSDate *)createdAt
{
    if (createdAt) {
        [self setObject:createdAt forKey:@"createdAt"];
    }
}

- (NSDate *)updatedAt
{
    return [self objectForKey:@"updatedAt"];
}

- (void)setUpdatedAt:(NSDate *)updatedAt
{
    if (updatedAt) {
        [self setObject:updatedAt forKey:@"updatedAt"];
    }
}

- (NSString *)fromUserId
{
    return [self objectForKey:@"fromUserId"];
}

- (void)setFromUserId:(NSString *)fromUserId
{
    if (fromUserId) {
        [self setObject:fromUserId forKey:@"fromUserId"];
    }
}

- (NSString *)toUserId
{
    return [self objectForKey:@"toUserId"];
}

-(void)setToUserId:(NSString *)toUserId
{
    if (toUserId) {
        [self setObject:toUserId forKey:@"toUserId"];
    }
}

- (NSString *)message
{
    return [self objectForKey:@"message"];
}

- (void)setMessage:(NSString *)message
{
    if (message) {
        [self setObject:message forKey:@"message"];
    }
}

- (MediaDic *)media
{
    return [self objectForKey:@"media"];
}

- (void)setMedia:(MediaDic *)media
{
    if (media) {
        [self setObject:media forKey:@"media"];
//        [self setObject:@"Media Message" forKey:@"message"];
    }
}

- (MessageType)messageType
{
    return [[self objectForKey:@"messageType"] integerValue];
}

- (void)setMessageType:(MessageType)messageType
{
    [self setObject:@(messageType) forKey:@"messageType"];
}

- (BOOL)read
{
    return [[self objectForKey:@"read"] integerValue];
}

- (void)setRead:(BOOL)read
{
    [self setObject:@(read) forKey:@"read"];
}

- (NSString *)userId
{
    return [self objectForKey:@"updatedAt"];
}

- (void)setUserId:(NSString *)userId
{
    if (userId)
        [self setObject:userId forKey:@"userId"];
}

- (NSString *)comment
{
    return [self objectForKey:@"comment"];
}

- (void)setComment:(NSString *)comment
{
    if (comment)
        [self setObject:comment forKey:@"comment"];
}

- (NSString *)thumbnail
{
    return [self objectForKey:@"thumbnail"];
}

- (void)setThumbnail:(NSString *)thumbnail
{
    if (thumbnail)
        [self setObject:thumbnail forKey:@"thumbnail"];
}

- (NSString *)mediaFile
{
    return [self objectForKey:@"mediaFile"];
}

- (void)setMediaFile:(NSString *)media
{
    if (media)
        [self setObject:media forKey:@"mediaFile"];
}

- (MediaType)mediaType
{
    return [[self objectForKey:@"mediaType"] integerValue];
}

- (void)setMediaType:(MediaType)type
{
    [self setObject:@(type) forKey:@"mediaType"];
}

- (BOOL)source
{
    return [[self objectForKey:@"source"] boolValue];
}

-(void)setSource:(BOOL)source
{
    [self setObject:@(source) forKey:@"source"];
}

- (CGSize)size
{
    return CGSizeFromString([self objectForKey:@"size"]);
}

- (void)setSize:(CGSize)size
{
    [self setObject:NSStringFromCGSize(size) forKey:@"size"];
}

@end

@implementation Message
@dynamic fromUser, toUser, message, media, type, read;

+ (NSString *)parseClassName {
    return @"Message";
}

+ (instancetype)media:(Media *)media toUser:(User *)user
{
    Message *message = [Message new];
    
    message.fromUser = [User me];
    message.toUser = user;
    message.media = media;
    message.type = kMessageTypeMedia;
    message.message = (media.type == kMediaTypePhoto) ? @"new photo message" : @"new video message";
    message.read = NO;
    
    return message;
}

+ (instancetype)message:(NSString *)text toUser:(User*)user
{
    Message *message = [Message new];
    
    message.fromUser = [User me];
    message.toUser = user;
    message.message = text;
    message.type = kMessageTypeText;
    message.read = NO;
    
    return message;
}

- (MessageDic*) dictionary
{
    MessageDic *d = [MessageDic new];
    
    d.objectId = self.objectId;
    d.createdAt = self.createdAt;
    d.updatedAt = self.updatedAt;
    d.fromUserId = self.fromUser.objectId;
    d.toUserId = self.toUser.objectId;
    d.message = self.message;
    d.media = self.media.dictionary;
    d.messageType = self.type;
    d.read = self.read;
    
    return d;
}

@end

#pragma mark Media

@implementation Media
@dynamic userId, comment, type, thumbnail, media, size, source;

+ (NSString *)parseClassName {
    return @"Media";
}

- (MediaDic*) dictionary
{
    MediaDic *d = [MediaDic new];
    
    d.objectId = self.objectId;
    d.createdAt = self.createdAt;
    d.updatedAt = self.updatedAt;
    d.userId = self.userId;
    d.comment = self.comment;
    d.thumbnail = self.thumbnail;
    d.mediaFile = self.media;
    d.mediaType = self.type;
    d.size = self.size;
    d.source = self.source;
    
    return d;
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
@dynamic nickname, where, whereUdatedAt, age, desc, media, photos, gender, simulated;

+ (User *)me
{
    return [User currentUser];
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

@end

@implementation SimulatedUsers

+ (void) createUsers
{
    [[SimulatedUsers new] createUsers];
}

+ (void) resetUsers
{
    PFQuery *query = [User query];
    
    [query whereKey:@"isSimulated" equalTo:@(YES)];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users, NSError * _Nullable error) {
        [users enumerateObjectsUsingBlock:^(User*  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *name = user.username;
            PFUser *loggedIn = [PFUser logInWithUsername:name password:name];
            if (!loggedIn) {
                NSLog(@"Error: FAILED TO LOGIN AS :%@", loggedIn);
            }
            else {
                NSLog(@"SETTING UP PROFILE IMAGE FOR %@", user.nickname);
                PFFile* file = loggedIn[@"originalPhoto"];
                NSString *filename = [@"ParseFiles/" stringByAppendingString:file.name];
                loggedIn[@"profileMedia"] = filename;
                [loggedIn save];
                [PFUser logOut];
            }
        }];
    }];
}

+ (void) resetMedia
{
    
}

- (void) createUsers
{
//    NSArray *names = @[@"가리온", @"가은", @"강다이", @"고루나", @"고운비", @"그레", @"그리미", @"글샘", @"기찬", @"길한", @"나나", @"나도람", @"나슬", @"난새", @"난한벼리", @"내누리", @"누니", @"늘새찬", @"늘품", @"늘해찬", @"다보라", @"다소나", @"다솜", @"다슴", @"다올", @"다조은", @"달래울", @"달비슬", @"대누리", @"드레", @"말그미", @"모도리", @"무아", @"미리내", @"미슬기", @"바다", @"바로", @"바우", @"밝음이", @"별아", @"보다나", @"봄이", @"비치", @"빛들", @"빛새온", @"빛찬온", @"사나래", @"새라", @"새로나", @"새미라", @"새하", @"샘나", @"소담", @"소란", @"솔다우니", @"슬미", @"아늘", @"아로미", @"아름이", @"아림", @"아음", @"애리", @"여슬", @"영아름", @"예달", @"온비", @"정다와", @"정아라미", @"조은", @"지예", @"진아", @"차니", @"찬샘", @"찬아람", @"참이", @"초은", @"파라", @"파랑", @"푸르나", @"푸르내", @"풀잎", @"하나", @"하나슬", @"하리", @"하은", @"한진이", @"한비", @"한아름", @"해나", @"해슬아", @"희라"];
    
    NSArray *names = @[ @"정아라미", @"조은", @"지예", @"진아", @"차니", @"찬샘", @"찬아람", @"참이", @"초은", @"파라", @"파랑", @"푸르나", @"푸르내", @"풀잎", @"하나", @"하나슬", @"하리", @"하은", @"한진이", @"한비", @"한아름", @"해나", @"해슬아", @"희라"];
    
    int i = 1;
    for (NSString *name in names) {
        float dx = ((long)(arc4random()%10000)-5000)/1000000.0;
        float dy = ((long)(arc4random()%10000)-5000)/1000000.0;
        
        PFGeoPoint *loc =  [PFGeoPoint geoPointWithLatitude:(37.52016263966829+dx) longitude:(127.0290097641595+dy)];
        [self newUserName:name location:loc photoIndex:i++];
    }
}

- (void) newUserName:(NSString*)name location:(PFGeoPoint*)geoLocation photoIndex:(int)idx
{
    NSLog(@"CREATING USER:%@ LO:%@ IDX:%d", name, geoLocation, idx);
        
    User *user = [User user];
    id usernameAndPassword = [ObjectIdStore newObjectId];
    
    user.username = usernameAndPassword;
    user.password = usernameAndPassword;
    user.nickname = name;
    user.where = geoLocation;
    user.whereUdatedAt = [NSDate date];
    user.simulated = YES;
    
    user.age = [User ageGroups][arc4random()%([User ageGroups].count)];
    user.desc = [User introductions][arc4random()%([User introductions].count)];
    user.gender = kGenderTypeFemale;
    
    BOOL ret = [user signUp];
    
    if (ret) {
        User *loggedIn = [User logInWithUsername:user.username password:user.password];
        if (!loggedIn) {
            NSLog(@"Error: FAILED TO LOGIN AS :%@", loggedIn);
        }
        else {
            NSLog(@"SETTING UP PROFILE IMAGE FOR %@", name);
            
            NSString* imageName = [NSString stringWithFormat:@"image%d", idx];
            Media *media = [self mediaFromImage:[UIImage imageNamed:imageName] size:CGSizeMake(1024, 1024)];
            loggedIn.media = media;
            [loggedIn addObjectsFromArray:[self createPhotos] forKey:@"photos"];
            
            NSLog(@"User:%@", loggedIn);
            [loggedIn save];
            NSLog(@"User Saved");
        }
    }
    else {
        NSLog(@"ERROR SIGNINGUP USER");
    }
}

- (NSArray<Media*>*) createPhotos
{
    NSUInteger count = arc4random()%10+1;
    
    NSLog(@"Creating %ld photos", count);
    NSMutableArray<Media*> *photos = [NSMutableArray array];
    for (int i =0; i<count; i++) {
        NSUInteger index = arc4random()%103+1;
        UIImage *photo = [UIImage imageNamed:[NSString stringWithFormat:@"image%ld", index]];
        [photos addObject:[self mediaFromImage:photo size:CGSizeMake(512, 512)]];
    }
    
    NSLog(@"Returning %ld photos array", count);
    return photos;
}

- (Media*) mediaFromImage:(UIImage*)original size:(CGSize) size
{
    UIImage *image = [self resizeAndPositionImage:original];
    UIImage *photo = __scaleImage(image, size);
    
    NSData *largeData = UIImageJPEGRepresentation(photo, kJPEGCompressionMedium);
    NSData *thumbnailData = __compressedImageData(largeData, kThumbnailWidth);
    
    Media *media = [Media object];
    media.size = photo.size;
    media.type = kMediaTypePhoto;
    media.source = kSourceTaken;
    
    media.thumbnail = [S3File saveImageData:thumbnailData completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    } progressBlock:nil];
    
    media.media = [S3File saveImageData:largeData completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
    
    [media saveInBackground];
    return media;
}

- (UIImage*) resizeAndPositionImage:(UIImage*)image
{
    CALayer *layer = [CALayer layer];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width, image.size.width), false, 0.0);
    layer.frame = CGRectMake(0, 0, image.size.width, image.size.width);
    layer.contents = (id) image.CGImage;
    layer.contentsGravity = kCAGravityBottom;
    layer.masksToBounds = YES;
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end

