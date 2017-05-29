//
//  SignupAndLogin.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "SignupAndLogin.h"

@interface SignupAndLogin () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UIButton *signup;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation SignupAndLogin

- (void)viewDidLoad {
    __LF
    
    [super viewDidLoad];
    self.signup.enabled = NO;
    [self startTimer];
    
    self.username.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"Username"];
    self.password.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"Password"];
    self.nickname.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"Nickname"];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self cleanup];
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)signup:(id)sender {
    User *me = [User object];
    
    me.username = self.username.text;
    me.password = self.password.text;
    me.email = self.username.text;
    me.nickname = self.nickname.text;
    
    [me signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self cleanup];
                if (self.failureHandler) {
                    self.failureHandler(error);
                }
            }];
        }
        else {
            if (succeeded) {
                [User logInWithUsernameInBackground:me.username password:me.password block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                    if (error) {
                        [self dismissViewControllerAnimated:YES completion:^{
                            [self cleanup];
                            if (self.failureHandler) {
                                self.failureHandler(error);
                            }
                        }];
                    }
                    else {
                        [[NSUserDefaults standardUserDefaults] setObject:user.username forKey:@"Username"];
                        [[NSUserDefaults standardUserDefaults] setObject:user.password forKey:@"Password"];
                        [[NSUserDefaults standardUserDefaults] setObject:user[fNickname] forKey:@"Nickname"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self dismissViewControllerAnimated:YES completion:^{
                            [self cleanup];
                            [[User me] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                                if (error) {
                                    if (self.failureHandler) {
                                        self.failureHandler(error);
                                    }
                                }
                                else {
                                    if (self.successHandler) {
                                        self.successHandler();
                                    }
                                }
                            }];
                        }];
                    }
                }];
            }
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __LF
    if ([self.username.text isValidEmail] && self.password.text.length>0 && self.nickname.text.length>0) {
        [textField resignFirstResponder];
        [self signup:textField];
    }
    
    return YES;
}

- (void)cleanup
{
    __LF
    [self.timer invalidate];
    self.timer = nil;
}

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        BOOL entered = YES;
        
        for (id view in [self.view viewWithTag:1199].subviews) {
            if ([view isKindOfClass:[UITextField class]]) {
                UITextField *tf = view;
                if (tf.text.length == 0) {
                    entered = NO;
                }
                if (tf.tag != 0 && tf.text.isValidEmail == NO) {
                    entered = NO;
                }
            }
        }
        
        self.signup.enabled = entered;
    }];
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
