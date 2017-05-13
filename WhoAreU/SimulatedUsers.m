//
//  SimulatedUsers.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "SimulatedUsers.h"
#import "S3File.h"

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
