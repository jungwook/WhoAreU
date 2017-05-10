//
//  Installation.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Parse/Parse.h>

#pragma mark Installation

@interface Installation : PFInstallation <PFSubclassing>
@property (retain) User *user;
@property NSUInteger credits;
@property (readonly) NSUInteger initialFreeCredits;
@property (readonly) NSUInteger openChatCredits;

+ (void)payForChatWithUser:(User*)user onViewController:(UIViewController *)viewController action:(StringBlock)actionBlock;
@end

