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
#import "MessageCenter.h"
#import <ParseUI/ParseUI.h>

@interface Tabs () <PFLogInViewControllerDelegate>

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
    
    VoidBlock initializationHandler = ^(void) {
        
        __LF
/*
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        logInViewController.delegate = self;
        UILabel *logo = [UILabel new];
        logo.font = [UIFont systemFontOfSize:60 weight:UIFontWeightLight];
        logo.text = @"Fuck!";
        logInViewController.logInView.logo = logo;
 
        [self presentViewController:logInViewController animated:YES completion:nil];
 */
        
        // User logged in so ready to initialize systems.
        [Engine initializeSystems];
        
        // Subscribe to channel user
        [MessageCenter subscribeToChannelUser];
        [MessageCenter setupUserToInstallation];

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

@end
