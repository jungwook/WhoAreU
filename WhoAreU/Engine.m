//
//  Engine.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Engine.h"
#include "TargetConditionals.h"

#define CHAT_FILE_PATH @"Chats"

@interface Engine() <CLLocationManagerDelegate>
// Location related
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation* currentLocation;

// Filesystem related
@property (strong, nonatomic) NSObject *lock;
@property (strong, nonatomic) NSURL* chatFilePath;

// User related
@property (weak, nonatomic) User *me;

// Operating System related
@property (nonatomic) BOOL simulator;

// Other structures
@property (nonatomic, strong) NSMutableDictionary *chats;

@end
@implementation Engine

+ (instancetype) new
{
    static id sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[self alloc] initOnce];
    });
    return sharedFile;
}

- (instancetype)initOnce
{
    __LF
    self = [super init];
    if (self) {
        self.lock = [NSObject new];
    }
    return self;
}

+ (void)initializeSystems
{
    [[Engine new] initializeSystems];
}

- (void)initializeSystems
{
    [self initFilesystemAndDataStructures];
    [self initLocationServices];
}

- (void) initFilesystemAndDataStructures
{
    self.chatFilePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:CHAT_FILE_PATH];
    self.chats = [NSMutableDictionary dictionaryWithContentsOfURL:self.chatFilePath];
    NSLog(@"CHATS Loaded with %ld chatrooms.", self.chats.allKeys.count);
}

+ (NSArray *)chatUsers
{
    return [Engine new].chats.allKeys;
}

+ (NSArray *)messagesFromUser:(User *)user
{
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    return [[[Engine new].chats objectForKey:user.objectId] sortedArrayUsingDescriptors:@[sd]];
}

+ (void)send:(id)message toUser:(User*)user
{
    Engine *engine = [Engine new];
    NSMutableArray *messages = [engine.chats objectForKey:user.objectId];
    if (!messages) {
        messages = [NSMutableArray array];
        [engine.chats setObject:messages forKey:user.objectId];
    }
    
    Message *msg = [Message object];
    msg.fromUser = [User me];
    msg.toUser = user;
    if ([message isKindOfClass:[Media class]]) {
        msg.media = message;
        msg.type = kMessageTypeMedia;
    }
    if ([message isKindOfClass:[NSString class]]) {
        msg.message = message;
        msg.type = kMessageTypeText;
    }
    msg.read = NO;
    
    MessageDic *dictionary = msg.dictionary;
    [messages addObject:dictionary];
    [engine saveChatsFile];
    [msg saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", [error localizedDescription]);
        }
        else {
            // send push
            [engine sendPushMessage:dictionary.message messageId:dictionary.objectId toUserId:user.objectId];
            
            // send local notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NEW_MESSAGE object:dictionary];
        }
    }];
}

- (void) sendPushMessage:textToSend messageId:(id)messageId toUserId:(id)userId
{
    const NSInteger maxLength = 100;
    NSUInteger length = [textToSend length];
    if (length >= maxLength) {
        textToSend = [textToSend substringToIndex:maxLength];
        textToSend = [textToSend stringByAppendingString:@"..."];
    }
    
    [PFCloud callFunctionInBackground:@"sendPushToUser"
                       withParameters:@{
                                        @"recipientId": userId,
                                        @"senderId":    [User me].objectId,
                                        @"message":     textToSend,
                                        @"messageId":   messageId,
                                        @"pushType":    @"pushTypeMessage"
                                        }
                                block:^(NSString *success, NSError *error) {
                                    if (!error) {
                                        
                                    }
                                    else {
                                        NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
                                    }
                                }];
}

- (void)saveChatsFile
{
    BOOL ret = [self.chats writeToURL:self.chatFilePath atomically:YES];
    if (ret) {
        NSLog(@"Message added successfully");
    } else {
        NSLog(@"Error saving chat file");
    }
}

+ (PFGeoPoint *)where
{
    Engine *engine = [Engine new];
    return [engine where];
}

- (PFGeoPoint*) where
{
    return POINT_FROM_CLLOCATION(self.currentLocation);
}

- (void)setSimulator:(BOOL)simulator
{
    _simulator = simulator;
    
    self.currentLocation = [[CLLocation alloc] initWithLatitude:SIMULATOR_LOCATION.latitude longitude:SIMULATOR_LOCATION.longitude];
}

- (void) initLocationServices
{
    // set simulator flag
    
#ifdef TARGET_OS_SIMULATOR
    self.simulator = YES;
    NSLog(@"Working with simulator");
#else
    self.simulator = NO;
    NSLog(@"Working with real device");
#endif

    self.me = [User me];
    
    NSLog(@"Initializing Location Services");
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
        
        NSLog(@"Allowing background location updates");
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusNotDetermined:
            [self.locationManager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        default:
            break;
    }
    
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"LOCATION SERVICES ENABLED");
    }
    else {
        NSLog(@"LOCATION SERVICES NOT ENABLED");
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    __LF
    
    CLLocation* location = [locations lastObject];
    if (!self.simulator) {
        self.currentLocation = location;
    }
}

- (void)setCurrentLocation:(CLLocation *)currentLocation
{
    _currentLocation = currentLocation;
    
    self.me.where = POINT_FROM_CLLOCATION(currentLocation);
    self.me.whereUdatedAt = [NSDate date];
    [self.me saveInBackground];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    __LF
    
    switch (status) {
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusNotDetermined:
            [self.locationManager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.locationManager startMonitoringSignificantLocationChanges];
            break;
        default:
            break;
    }
}


@end
