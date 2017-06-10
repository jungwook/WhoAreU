//
//  LoginOrSignup.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LoginOrSignup.h"
#import "SignupAndLogin.h"
#import "Login.h"

@interface LoginOrSignup ()

@end

@implementation LoginOrSignup

- (void)viewDidLoad {
    __LF
    
    [super viewDidLoad];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    VoidBlock successHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    };
    
    ErrorBlock failureHandler = ^(NSError* error) {
        LogError;
        id message = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
        __alert(@"ERROR", message, ^(UIAlertAction *action) {
        }, nil, self);
    };
    
    if ([segue.identifier isEqualToString:@"SignupAndLogin"]) {
        SignupAndLogin *vc = segue.destinationViewController;
        vc.successHandler = successHandler;
        vc.failureHandler = failureHandler;
    }
    else if ([segue.identifier isEqualToString:@"Login"]) {
        Login *vc = segue.destinationViewController;
        vc.successHandler = successHandler;
        vc.failureHandler = failureHandler;
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
