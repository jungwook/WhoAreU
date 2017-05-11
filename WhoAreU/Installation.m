//
//  Installation.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Installation.h"

@implementation Installation
@dynamic user, credits, initialFreeCredits, openChatCredits;

- (NSUInteger)initialFreeCredits
{
    return 1000;
}

- (NSUInteger)openChatCredits
{
    return 25;
}

+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(StringBlock)actionBlock
{
    if ([Engine userExists:user]) {
        if (actionBlock) {
            actionBlock(nil);
            // Example ... [self performSegueWithIdentifier:@"Chat" sender:user];
        }
        return;
    }
    Installation *install = [Installation currentInstallation];
    
    BOOL enoughCredits = install.credits > install.openChatCredits;
    
    NSString *message = enoughCredits ?  [NSString stringWithFormat:@"You have a total of %ld credits.\nTo continue %ld credits will be charged. Send your first hello message to proceed.", install.credits, install.openChatCredits] : [NSString stringWithFormat:@"You need %ld credits to open a new chat!\n\nYou currently have a total of %ld credits. Would you like to buy more credits?", install.openChatCredits, install.credits];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Initiate Chat" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    void(^buyhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        NSLog(@"Buy more credits");
        
        UIViewController *vc = [viewController.storyboard instantiateViewControllerWithIdentifier:@"Credits"];

        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        [viewController presentViewController:vc animated:YES completion:nil];
    };
    void(^okhandler)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action) {
        install.credits -= install.openChatCredits;
        NSLog(@"Install:%@", install);
        [install saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSString *message = alert.textFields.firstObject.text;
                if (actionBlock) {
                    actionBlock(message);
                }
            }
        }];
    };
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDefault handler:enoughCredits ? okhandler : buyhandler];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
    
    if (enoughCredits) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            
        }];
    }
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
