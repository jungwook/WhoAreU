//
//  AppDelegate.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.engine = [Engine new];
    
    [self setupAWSCredentials];

    // register subclasses
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"WhoAreU";
        configuration.server = @"http://parse.kr:1336/WhoAreU";
        configuration.clientKey = @"whoareu";
        configuration.localDatastoreEnabled = YES;
    }]];
    
    [self setupAWSDefaultACLs];
    [self registerForNotifications:application launchOptions:launchOptions];
//    [SimulatedUsers createUsers];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)setupAWSDefaultACLs
{
    PFACL *defaultACL = [PFACL ACL];
    defaultACL.publicReadAccess = YES;
    defaultACL.publicWriteAccess = YES;
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
}

- (void)setupAWSCredentials
{
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1 identityPoolId:@"us-east-1:cf811cfd-3215-4274-aec5-82040e033bfe"];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionAPNortheast2 credentialsProvider:credentialsProvider];
    configuration.maxRetryCount = 3;
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    
    [AWSLogger defaultLogger].logLevel = AWSLogLevelError;
}

- (void)registerForNotifications:(UIApplication*)application launchOptions:(id)launchOptions
{
    __LF
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 10000
    NSLog(@"SYSTEM IS GREATER THAN 10.0");
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
     {
         if( !error )
         {
             [application registerForRemoteNotifications];  // required to get the app to do anything at all about push notifications
             NSLog( @"Push registration successfull." );
         }
         else
         {
             NSLog( @"Push registration FAILED" );
             NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
             NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
         }
     }];
#else
    NSLog(@"SYSTEM IS LESS THAN 10.0");
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil]];
    [application registerForRemoteNotifications];
    
    NSDictionary *payload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        NSLog(@"PAYLOAD:%@", payload);
    }
    
    if( launchOptions != nil )
    {
        NSLog( @"registerForPushWithOptions:" );
    }
#endif
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    __LF
    PFInstallation *install = [PFInstallation currentInstallation];
    [install setDeviceTokenFromData:deviceToken];
    [install saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        [install setDeviceTokenFromData:deviceToken];
        [PFPush subscribeToChannelInBackground:@"Main" block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"application successfully subscribed to push notifications on the broadcast channel.");
                [[Engine new] setSimulatorStatus:kSimulatorStatusDevice];
            } else {
                NSLog(@"application failed to subscribe to push notifications on the broadcast channel.");
            }
        }];
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    __LF
    NSLog(@"Push notifications are not supported in the iOS Simulator.");
    NSLog(@"Error:%@", error.localizedDescription);
    
    [[Engine new] setSimulatorStatus:kSimulatorStatusSimulator];
}

-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // iOS 10 will handle notifications through other methods
    
    switch (application.applicationState) {
        case UIApplicationStateActive:
            NSLog( @"Notification in FOREGROUND" );
            break;
        case UIApplicationStateInactive:
            NSLog( @"Notification in INACTIVE" );
            break;
        case UIApplicationStateBackground:
            NSLog( @"Notification in BACKGROUND" );
            break;
    }
    
//    [Engine handlePushUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    id userInfo = notification.request.content.userInfo;
    
    NSLog( @"Handle push from foreground" );
    NSLog(@"%@", userInfo);
    UNNotificationPresentationOptions option = UNNotificationPresentationOptionNone; //[Engine handlePushUserInfo:userInfo];

    if (completionHandler)
        completionHandler(option);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler
{
    id userInfo = response.notification.request.content.userInfo;

    NSLog(@"Handle push from background or closed" );
    NSLog(@"%@", userInfo);

//    [Engine handlePushUserInfo:userInfo];
    completionHandler();
}

@end
