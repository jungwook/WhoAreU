//
//  Tabs.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Tabs.h"
#import "SignUp.h"
#import "ObjectIdStore.h"
#import "S3File.h"

@interface Tabs ()

@end

@implementation Tabs

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [self checkLoginStatusAndProceed];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)checkLoginStatusAndProceed
{
    [User logOut];
    User *user = [User me];
    
    VoidBlock initializationHandler = ^(void) {
        NSLog(@"User %@ logged in", [User me]);
    };
    
    if (user) {
        [user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            initializationHandler();
        }];
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

- (void) subscribeToChannelCurrentUser
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (!currentInstallation[@"user"]) {
        currentInstallation[@"user"] = [User me];
        [currentInstallation saveInBackground];
        NSLog(@"CURRENT INSTALLATION: saving user to Installation");
    }
    else {
        NSLog(@"CURRENT INSTALLATION: Installation already has user. No need to set");
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

@end
