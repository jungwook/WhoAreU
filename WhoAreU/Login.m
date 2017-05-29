//
//  Login.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Login.h"

@interface Login () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *login;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation Login

- (void)viewDidLoad {
    __LF
    [super viewDidLoad];
    
    self.login.enabled = NO;
    
    self.username.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"Username"];
    self.password.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"Password"];
    [self startTimer];

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

- (void)cleanup
{
    __LF
    [self.timer invalidate];
    self.timer = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __LF
    if ([self.username.text isValidEmail] && self.password.text.length>0) {
        [textField resignFirstResponder];
        [self login:textField];
    }
    
    return YES;
}

- (IBAction)login:(id)sender {
    [User logInWithUsernameInBackground:self.username.text password:self.password.text block:^(PFUser * _Nullable user, NSError * _Nullable error) {
        if (error) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self cleanup];
                if (self.failureHandler) {
                    self.failureHandler(error);
                }
            }];
        }
        else {
            [self dismissViewControllerAnimated:YES completion:^{
                [[NSUserDefaults standardUserDefaults] setObject:user.username forKey:@"Username"];
                [[NSUserDefaults standardUserDefaults] setObject:user.password forKey:@"Password"];
                [[NSUserDefaults standardUserDefaults] synchronize];
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
        
        self.login.enabled = entered;
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
