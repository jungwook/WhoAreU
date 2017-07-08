//
//  MainTabs.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MainTabs.h"
#import "MessageCenter.h"
#import <ParseUI/ParseUI.h>
#import <Parse/PFConfig.h>

@interface MainTabs ()

@end

@implementation MainTabs

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
        [self performSegueWithIdentifier:@"Entry" sender:self];
    }
}

@end
