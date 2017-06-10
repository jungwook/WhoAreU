//
//  Tabs.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Tabs.h"
#import "SignUp.h"
#import "MessageCenter.h"
#import <ParseUI/ParseUI.h>
#import <Parse/PFConfig.h>

@interface Tabs () <PFLogInViewControllerDelegate>

@end

@implementation Tabs

- (void)viewDidLoad {
    [super viewDidLoad];

    Notification(kNotificationNewChatMessage, notificationNewChatMessage:);
}

- (void) setTabItemBadgeValue
{
    UITabBarItem *chatBarItem = [self.tabBar.items objectAtIndex:3];
    
    NSUInteger count = [MessageCenter countAllUnreadMessages];
    chatBarItem.badgeValue = count > 0 ? @(count).stringValue : nil;
}

- (void) notificationNewChatMessage:(NSNotification*) notification
{
    [self setTabItemBadgeValue];
}

- (void) forceLoadViewControllers
{
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UINavigationController class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [obj.childViewControllers.firstObject view];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [obj view];
            });
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setTabItemBadgeValue];
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

        [[PFConfig getConfigInBackground] continueWithSuccessBlock:^id _Nullable(BFTask<PFConfig *> * _Nonnull task) {
            
            [Engine initializeSystems];
            
            PostNotification(kNotificationUserLoggedInMessage, nil);
            [MessageCenter initializeCommunicationSystem];
            // User logged in so ready to initialize systems.
            
            // Subscribe to channel user
            [MessageCenter subscribeToChannelUser];
            [MessageCenter setupUserToInstallation];
            //        [MessageCenter processFetchMessages];
            
            // force load child view controllers
            [self forceLoadViewControllers];
            [MessageCenter setSystemBadge];        
            return nil;
        }];
    };
    
    if (user) {
        [user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            initializationHandler();
        }];
    }
    else {
        if (nil == [User me]) {
            [self performSegueWithIdentifier:@"Entry" sender:self];
        }
    }
}

- (void) backup
{
    NSString *prevUserName = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    
    if (prevUserName && [User logInWithUsername:prevUserName password:prevUserName]) {
        NSLog(@"Logged in as previous user");
//        initializationHandler();
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
            user.channel = intro;
            [user setGenderTypeFromString:gender];
            
            [[NSUserDefaults standardUserDefaults] setObject:usernameAndPassword forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [PFUser logInWithUsernameInBackground:user.username password:user.password block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                        if (!error) {
                            [signup dismissViewControllerAnimated:YES completion:nil];
//                            initializationHandler();
                            
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

@end
