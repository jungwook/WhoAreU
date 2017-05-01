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
@property (nonatomic, strong) NSTimer *timeKeeper;

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
        self.simulatorStatus = kSimulatorStatusUnknown;
    }
    return self;
}

+ (void)initializeSystems
{
    [[Engine new] initializeSystems];
}

- (void)initializeSystems
{
    // set me to [User me]. This assumes we've logged on already.
    self.me = [User me];

    [self initFilesystemAndDataStructures];
    [self initLocationServices];
    [self setInitialized:YES];
    
    // Fetching outstanding messages just in case.
    [self fetchOutstandingMessages];
}

- (void)setSimulatorStatus:(SimulatorStatus)simulatorStatus
{
    _simulatorStatus = simulatorStatus;
    
    switch (simulatorStatus) {
        case kSimulatorStatusUnknown:
            NSLog(@"System is Unknown");
            break;
            
        case kSimulatorStatusDevice:
            NSLog(@"System is a Device");
            break;
            
        case kSimulatorStatusSimulator:
            NSLog(@"System is a Simulator");
            break;
            
        default:
            break;
    }
}

//#define RESET_CHAT_FILE

- (void) initFilesystemAndDataStructures
{
    self.chatFilePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:CHAT_FILE_PATH];
    
#ifndef RESET_CHAT_FILE
    self.chats = [NSMutableDictionary dictionaryWithContentsOfURL:self.chatFilePath];
#endif
    
    if (!self.chats) {
        self.chats = [NSMutableDictionary dictionary];
    }
    
    NSLog(@"CHATS Loaded with %ld chatrooms.", self.chats.allKeys.count);
    
    self.timeKeeper = [NSTimer scheduledTimerWithTimeInterval:SIMULATOR_FETCH_INTERVAL target:self selector:@selector(timeKeep) userInfo:nil repeats:YES];
}

- (void) timeKeep
{
    if (self.simulatorStatus == kSimulatorStatusSimulator && self.initialized) {
        [self fetchOutstandingMessages];
    }
}

+ (void) loadMessage:(id)messageId
{
    NSLog(@"===========================================");
    Message *message = [Message objectWithoutDataWithObjectId:messageId];
    
    [message fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            if (message.media) {
                [message.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (!error) {
                        [[Engine new] readAndAddMessageToSystem:message];
                    }
                    else {
                        NSLog(@"ERROR:%@", error.localizedDescription);
                    }
                }];
            }
            else {
                [[Engine new] readAndAddMessageToSystem:message];
            }
        }
        else {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
}

- (void) readAndAddMessageToSystem:(Message*)message
{
    [message fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        User *fromUser = message.fromUser;
        
        message.read = YES;
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self addToUser:fromUser message:message.dictionary push:NO];
            }
            else {
                NSLog(@"ERROR:%@", error.localizedDescription);
            }
        }];
    }];
}

- (void) addToUser:(User*)user message:(MessageDic*)dictionary push:(BOOL)push
{
    NSMutableArray *messages = [self messagesFromUser:user];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", dictionary.objectId];
    NSArray *filter = [messages filteredArrayUsingPredicate:predicate];
    
    if (filter.count > 0) {
        NSLog(@"============================================");
        NSLog(@"ERROR:Cannot have multiple entries of message:%@", dictionary.objectId);
    }
    else {
        [messages addObject:dictionary];
        [self postNewMessageNotification:dictionary];
        [Engine save];
        if (push) {
            [Engine sendPushMessage:dictionary.message messageId:dictionary.objectId toUserId:user.objectId];
        }
    }
}

- (void) postNewMessageNotification:(MessageDic*)dictionary
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_NEW_MESSAGE object:dictionary];
}

+ (void) fetchOutstandingMessages
{
    [[Engine new] fetchOutstandingMessages];
}

- (void) fetchOutstandingMessages
{
    NSLog(@"Fetching Outstanding Messages For User:%@", [User me]);
    
    PFQuery *query = [Message query];
    
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:@"read" equalTo:@(NO)];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable messages, NSError * _Nullable error) {
        NSLog(@"Found %ld messages", messages.count);
        [messages enumerateObjectsUsingBlock:^(id  _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
            [self readAndAddMessageToSystem:message];
        }];
    }];
}

+ (NSArray *)chatUsers
{
    return [Engine new].chats.allKeys;
}

+ (NSArray *)messagesFromUser:(User *)user
{
    Engine *engine = [Engine new];

    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    
    NSMutableArray *messages = [engine messagesFromUser:user];
    return [messages sortedArrayUsingDescriptors:@[sd]];
}

- (NSMutableArray*) messagesFromUser:(User*)user
{
    NSMutableArray *messages = [self.chats objectForKey:user.objectId];
    
    if (!messages) {
        messages = [NSMutableArray array];
        [self.chats setObject:messages forKey:user.objectId];
    }
    return messages;
}

+ (void)send:(id)msgToSend toUser:(User*)user
{
    Engine *engine = [Engine new];
    
    Message *message = nil;
    if ([msgToSend isKindOfClass:[Media class]]) {
        message = [Message media:msgToSend toUser:user];
    }
    if ([msgToSend isKindOfClass:[NSString class]]) {
        message = [Message message:msgToSend toUser:user];
    }
    message.read = NO;

    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", [error localizedDescription]);
        }
        else {
            [engine addToUser:user message:message.dictionary push:YES];
        }
    }];
}

+ (void) sendPushMessage:(NSString*)textToSend messageId:(id)messageId toUserId:(id)userId
{
    const NSInteger maxLength = 100;
    NSUInteger length = [textToSend length];
    if (length >= maxLength) {
        textToSend = [textToSend substringToIndex:maxLength];
        textToSend = [textToSend stringByAppendingString:@"..."];
    }
    
    id params = @{
                  @"recipientId": userId,
                  @"senderId":    [User me].objectId,
                  @"message":     textToSend,
                  @"messageId":   messageId,
                  @"pushType":    @"pushTypeMessage"
                  };
    
    [PFCloud callFunctionInBackground:@"sendPushToUser" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
        }
        else {
            NSLog(@"PUSH SENT:%@", object);
        }
    }];
}

+ (void) save
{
    [[Engine new] saveChatsFile];
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

- (void) initLocationServices
{
    // Initializing location services.
    
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
    switch (self.simulatorStatus) {
        case kSimulatorStatusDevice:
            self.currentLocation = location;
            break;
            
        case kSimulatorStatusSimulator:
            self.currentLocation = [[CLLocation alloc] initWithLatitude:SIMULATOR_LOCATION.latitude longitude:SIMULATOR_LOCATION.longitude];
            
        default:
            break;
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
