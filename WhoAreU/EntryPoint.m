//
//  EntryPoint.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "EntryPoint.h"

@interface EntryPoint ()

@end

@implementation EntryPoint

- (void)viewDidLoad
{
    __LF
    [super viewDidLoad];
    
//    [self performSegueWithIdentifier:@"Signup" sender:self];

    
}

- (void)viewDidAppear:(BOOL)animated
{
    [User logOut];
    if (nil == [User me]) {
        [self performSegueWithIdentifier:@"Entry" sender:self];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
