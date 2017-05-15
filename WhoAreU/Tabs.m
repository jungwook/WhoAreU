//
//  Tabs.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Tabs.h"
#import "Profile.h"
#import "SignUp.h"
#import "S3File.h"
#import "NSData+GZIP.h"
#import "MessageCenter.h"

@interface Tabs ()

@end

@implementation Tabs

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) forceLoadViewControllers
{
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UINavigationController class]]) {
            [obj.childViewControllers.firstObject view];
        }
        else {
            [obj view];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self checkLoginStatusAndProceed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)checkLoginStatusAndProceed
{
    //    [User logOut];
    User *user = [User me];
    [self dictionaryCompare];
    
    VoidBlock initializationHandler = ^(void) {
        
        // User logged in so ready to initialize systems.
        [Engine initializeSystems];
        
        // Subscribe to channel user
        [self subscribeToChannelCurrentUser];

        // force load child view controllers
//        [self forceLoadViewControllers];
        [MessageCenter setSystemBadge];
    };
    
    if (user) {
        [user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            initializationHandler();
        }];
    }
    else {
        NSString *prevUserName = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
        
        if (prevUserName && [User logInWithUsername:prevUserName password:prevUserName]) {
            NSLog(@"Logged in as previous user");
            initializationHandler();
        }
        else {
            SignUp *signup = [[[NSBundle mainBundle] loadNibNamed:@"SignUp" owner:self options:nil] firstObject];
            signup.modalPresentationStyle = UIModalPresentationOverFullScreen;
            signup.completionBlock = ^(SignUp* signup,
                                       id nickname,
                                       id intro,
                                       id age,
                                       id gender,
                                       BOOL mediaSet,
                                       MediaType type,
                                       NSData *thumbnail,
                                       NSData *photo,
                                       NSData* movie,
                                       SourceType source)
            {
                User *user = [User object];
                id usernameAndPassword = [ObjectIdStore newObjectId];
                user.username = usernameAndPassword;
                user.password = usernameAndPassword;
                user.nickname = nickname;
                user.age = age;
                user.desc = intro;
                [user setGenderTypeFromString:gender];
                
                [[NSUserDefaults standardUserDefaults] setObject:usernameAndPassword forKey:@"username"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [PFUser logInWithUsernameInBackground:user.username password:user.password block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                            if (!error) {
                                [signup dismissViewControllerAnimated:YES completion:nil];
                                [self subscribeToChannelCurrentUser];
                                initializationHandler();
                                
                                if (type == kMediaTypePhoto && mediaSet) {
                                    NSString *thumbFileName = [S3File saveImageData:thumbnail completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error) {
                                        if (error) {
                                            NSLog(@"ERROR:%@", error.localizedDescription);
                                        }
                                    } progressBlock:nil];
                                    
                                    NSString *mediaFileName = [S3File saveImageData:photo completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
                                        if (error) {
                                            NSLog(@"ERROR:%@", error.localizedDescription);
                                        }
                                    }];
                                    
                                    UIImage *image = [UIImage imageWithData:photo];
                                    
                                    Media *media = [Media object];
                                    media.size = image.size;
                                    media.media = mediaFileName;
                                    media.thumbnail = thumbFileName;
                                    media.type = kMediaTypePhoto;
                                    media.source = source;
                                    
                                    [User me].media = media;
                                    [[User me] saveInBackground];
                                }
                                else if (mediaSet) {
                                    [S3File saveImageData:thumbnail completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error) {
                                        [S3File saveMovieData:movie completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
                                            if (succeeded && !error) {
                                                UIImage *image = [UIImage imageWithData:thumbnail];
                                                
                                                Media *media = [Media object];
                                                media.size = image.size;
                                                media.media = mediaFile;
                                                media.thumbnail = thumbnailFile;
                                                media.type = kMediaTypeVideo;
                                                media.source = source;
                                                [User me].media = media;
                                                [[User me] saveInBackground];
                                            }
                                            else {
                                                NSLog(@"ERROR:%@", error.localizedDescription);
                                            }
                                        }];
                                    } progressBlock:nil];
                                }
                            }
                            else {
                                [signup setInfo:[NSString stringWithFormat:@"Some error occured:%@", error.localizedDescription]];
                            }
                        }];
                    }
                    else {
                        [signup setInfo:[NSString stringWithFormat:@"Some error occured:%@", error.localizedDescription]];
                    }
                }];
            };
            [self presentViewController:signup animated:YES completion:nil];
        }
    }
}

- (void) subscribeToChannelCurrentUser
{
    User *me = [User me];
    
    PFInstallation *install = [PFInstallation currentInstallation];
    //    install[@"deviceToken"] = install[@"deviceToken"];
    //    install[@"deviceType"] = install.deviceType;
    [install addUniqueObject:me.objectId forKey:@"channels"];
    NSLog(@"Installation:%@", install);
    [install saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
    
    User *installUser = install[fUser];
    BOOL sameUser = [installUser.objectId isEqualToString:me.objectId];
    if (!sameUser) {
        me.credits = me.initialFreeCredits;
        NSLog(@"Adding %ld free credits", me.credits);
        [me saveInBackground];
        install[@"deviceToken"] = install[@"deviceToken"];
        install[fUser] = me;
        NSLog(@"CURRENT INSTALLATION: saving user to Installation.");
        [install saveInBackground];
    }
    else {
        NSLog(@"CURRENT INSTALLATION: Installation is already set to current user. No need to update");
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) dictionaryCompare
{
    NSDictionary* dic = [User me].dictionary;
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dic format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSLog(@"ORIGINAL:%ld", data.length);
    NSData *compressed = [data gzippedDataWithCompressionLevel:1.0];
    NSLog(@"COMPRESSED:%ld", compressed.length);
    NSData *uncompressed = [compressed gunzippedData];
    NSLog(@"UNCOMPRESSED:%ld", uncompressed.length);

    NSDictionary *n = [NSPropertyListSerialization propertyListWithData:uncompressed options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    
    if ([n.description compare:dic.description] == NSOrderedSame) {
        NSLog(@"Good!!%@", n);
    }
    else {
        NSLog(@"User Data:%@", dic);
        NSLog(@"New Data:%@", n);
    }
}

@end
