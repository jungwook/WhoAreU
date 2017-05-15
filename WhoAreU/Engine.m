//
//  Engine.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Engine.h"
#import "TargetConditionals.h"
#import "S3File.h"

#pragma mark Queue

@interface Queue()
@property (nonatomic) NSUInteger capacity;
@property (nonatomic, strong) NSURL *filePath;
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation Queue

+ (instancetype)new
{
    return [self initWithCapacity:200];
}

+ (instancetype)initWithCapacity:(NSUInteger)numItems
{
    static id sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[self alloc] initOnceWithCapacity:numItems];
    });
    return sharedFile;
}

- (NSArray *)objects
{
    return self.array;
}

+ (NSArray*)objects
{
    return [Queue new].objects;
}

- (NSUInteger)count
{
    return self.array.count;
}

+ (NSUInteger)count
{
    return [Queue new].count;
}

- (instancetype)initOnceWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        self.array = [NSMutableArray array];
        if (!self.array) {
            self.array = [NSMutableArray new];
        }
        self.capacity = numItems;
    }
    return self;
}

+ (void)clear
{
    [[Queue new] clear];
}

- (void)clear
{
    @synchronized (self.array) {
        [self.array removeAllObjects];
        [self saveArray];
    }
}

+ (void)addObject:(id)anObject
{
    [[Queue new] addObject:anObject];
}

- (void) addObject:(id)anObject
{
    if (anObject) {
        if (self.array.count == self.capacity) {
            [self.array removeLastObject];
        }
        @synchronized (self.array) {
            [self.array insertObject:anObject atIndex:0];
            [self saveArray];
        }
    }
}

- (void) saveArray
{
    BOOL ret = [self.array writeToURL:self.filePath atomically:YES];
    if (!ret) {
        NSLog(@"Error writing to channel file");
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self.array objectAtIndex:index];
}

+ (id)objectAtIndex:(NSUInteger)index
{
    return [[Queue new] objectAtIndex:index];
}

@end

#pragma mark Counter

@implementation Counter

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
    self = [super init];
    if (self) {
        self.counters = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) setCount:(NSUInteger)count completion:(VoidBlock)handler
{
    if (count) {
        id counterId = [ObjectIdStore newObjectId];
        if (counterId) {
            id object = @{
                          @"count" : @(count),
                          @"handler" : handler
                          };
            [self.counters setObject:object forKey:counterId];
        }
        return counterId;
    }
    else {
        if (handler) {
            handler();
        }
        return nil;
    }
}

- (void) decreaseCount:(id)counterId
{
    id object = [self.counters objectForKey:counterId];
    VoidBlock handler = [object objectForKey:@"handler"];
    NSUInteger count = [[object objectForKey:@"count"] integerValue] - 1;
    if (count <= 0) {
        count = 0;
        if (handler) {
            handler();
        }
    }
    id updatedObject = @{
                  @"count" : @(count),
                  @"handler" : handler
                  };
    [self.counters setObject:updatedObject forKey:counterId];
}

@end

#pragma mark Engine

@interface Engine() <CLLocationManagerDelegate>

// Location and heading related
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation* currentLocation;
@property (nonatomic) CLLocationDirection heading;

// Filesystem related
@property (strong, nonatomic) NSObject *lock;

// User related
@property (weak, nonatomic) User *me;

// Operating System related
@property (nonatomic, strong) NSTimer *timeKeeper;

// Other structures
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
//    [self fetchOutstandingMessages];
}

- (void)setInitialized:(BOOL)initialized
{
    _initialized = initialized;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSystemInitialized object:nil];
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
    self.timeKeeper = [NSTimer scheduledTimerWithTimeInterval:SIMULATOR_FETCH_INTERVAL target:self selector:@selector(timeKeep) userInfo:nil repeats:YES];
    
//    [self refreshChatUsers];
}

- (void) timeKeep
{
    if (self.simulatorStatus == kSimulatorStatusSimulator && self.initialized) {
//        [Engine fetchOutstandingMessages];
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
    
    //    if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
    //        NSLog(@"Allowing background location updates");
    //        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    //    }
    
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
    
    //    [self.locationManager startMonitoringSignificantLocationChanges];
    
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    [self.locationManager startUpdatingLocation];
    
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"LOCATION SERVICES ENABLED");
    }
    else {
        NSLog(@"LOCATION SERVICES NOT ENABLED");
    }
    
    [self.locationManager startUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    self.heading = newHeading.magneticHeading;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
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

+ (CLLocationDirection)heading
{
    return [Engine new].heading;
}

- (void)setCurrentLocation:(CLLocation *)currentLocation
{
    _currentLocation = currentLocation;
    
    self.me.where = POINT_FROM_CLLOCATION(currentLocation);
    self.me.whereUpdatedAt = [NSDate date];
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

/*
- (void) refreshChatUsers
{
    PFQuery *query = [Message query];
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:@"read" equalTo:@(FALSE)];
    [query includeKey:@"toUser"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable messages, NSError * _Nullable error) {
        
        [messages enumerateObjectsUsingBlock:^(Message*  _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![[Engine chatUserIds] containsObject:message.objectId]) {
                [self.chats setObject:[NSMutableArray array] forKey:message.objectId];
                [Engine save];
                [Engine postNewUserMessageNotification:nil];
            }
        }];
    }];
}

+ (NSArray *)chatUserIds
{
    return [Engine new].chats.allKeys;
}

+ (void)readMessage:(MessageDic *)dictionary
{
    id messageId = dictionary.objectId;
    
    Message *message = [Message objectWithoutDataWithObjectId:messageId];
    
    message.read = YES;
    [message saveInBackground];
}

- (void) addMessageToSystem:(Message*)message completion:(VoidBlock) handler
{
    __LF
    UserBlock addToUser = ^(User* fromUser) {
        message.read = YES;
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self addToUser:fromUser message:message.dictionary push:NO completion:handler];
            }
            else {
                NSLog(@"ERROR:Could not update read=YES to message");
            }
        }];
    };
    
    User *fromUser = message.fromUser;
    if (message.media) {
        [message.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (!error) {
                addToUser(fromUser);
            }
            else {
                NSLog(@"Error Fetching Media from Message:%@", message);
            }
        }];
    }
    else {
        addToUser(fromUser);
    }
}

- (void) addToUser:(User*)user message:(MessageDic*)dictionary push:(BOOL)push completion:(VoidBlock)handler
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
        [Engine save];
        if (push) {
            [Engine sendPushMessage:dictionary.message messageId:dictionary.objectId toUserId:user.objectId];
        }
        if (handler) {
            handler();
        }
    }
}

+ (void) setSystemBadge
{
    [Engine countUnreadMessages:^(NSUInteger count) {
        NSLog(@"counted %ld unread messages", count);
        PFInstallation *install = [PFInstallation currentInstallation];
        if (count != install.badge) {
            install.badge = count;
            [install saveInBackground];
        }
    }];
}

+ (NSUInteger)unreadMessagesFromUser:(User *)user
{
    return 0;
}
*/


/*
+ (void) fetchOutstandingMessages
{
    Counter *counter = [Counter new];

    NSLog(@"Fetching Outstanding Messages For User:%@", [User me].nickname);
    
    PFQuery *query = [Message query];
    
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:@"read" equalTo:@(NO)];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable messages, NSError * _Nullable error) {
        NSLog(@"Found %ld messages", messages.count);
        id countId = [counter setCount:messages.count completion:^{
            [Engine setSystemBadge];
        }];

        [messages enumerateObjectsUsingBlock:^(Message*  _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
            [counter decreaseCount:countId];
            [Engine postNewUserMessageNotification:@{
                                                 fSenderId : message.fromUser.objectId
                                                 }];
        }];
    }];
}

+ (void) loadUnreadMessagesFromUser:(User *)user completion:(VoidBlock)handler
{
    Counter *counter = [Counter new];
    PFQuery *query = [Message query];
    
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:fFromUser equalTo:user];
    [query whereKey:@"read" equalTo:@(NO)];
    [query orderByAscending:fCreatedAt];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable messages, NSError * _Nullable error) {
        NSLog(@"Found %ld messages", messages.count);

        id countId = [counter setCount:messages.count completion:^{
            NSLog(@"Counter reached 0. running completion handler");
            if (handler) {
                handler();
            }
        }];

        [messages enumerateObjectsUsingBlock:^(id  _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
            [[Engine new] addMessageToSystem:message completion:^{
                [counter decreaseCount:countId];
            }];
        }];
    }];
}

+ (void) countUnreadMessages:(CountBlock)handler
{
    PFQuery *query = [Message query];
    
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:@"read" equalTo:@(NO)];
    
    [query countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (handler) {
            handler(number);
        }
    }];
}

+ (void)deleteChatWithUserId:(id)userId
{
    Engine *engine = [Engine new];
    
    [engine.chats removeObjectForKey:userId];
    [Engine save];
}

+ (void) countUnreadMessagesFromUser:(User*)user completion:(CountBlock)handler
{
    PFQuery *query = [Message query];
    
    [query whereKey:@"toUser" equalTo:[User me]];
    [query whereKey:fFromUser equalTo:user];
    [query whereKey:@"read" equalTo:@(NO)];

    [query countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (handler) {
            handler(number);
        }
    }];
}

+ (NSArray *)messagesFromUser:(User *)user
{
    NSAssert(user != nil, @"User cannot be nil");
    Engine *engine = [Engine new];

    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:fCreatedAt ascending:YES];
    
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

+ (BOOL)userExists:(User *)user
{
    NSArray *users = [Engine chatUserIds];

    __block BOOL ret = NO;
    [users enumerateObjectsUsingBlock:^(id _Nonnull userId, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([userId isEqualToString:user.objectId]) {
            ret = YES;
            *stop = YES;
        }
    }];
    return ret;
}

+ (void)send:(id)msgToSend toUser:(User*)user completion:(VoidBlock)handler
{
    if (msgToSend == nil) {
        if (handler) {
            handler();
        }
        return;
    }
    
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
            MessageDic *dictionary = message.dictionary;
            [engine addToUser:user message:dictionary push:YES completion:handler];
        }
    }];
}

+ (void) sendPushMessageV2:(NSString*)textToSend messageId:(id)messageId toUserId:(id)userId
{
    const NSInteger maxLength = 100;
    NSUInteger length = [textToSend length];
    if (length >= maxLength) {
        textToSend = [textToSend substringToIndex:maxLength];
        textToSend = [textToSend stringByAppendingString:@"..."];
    }
    
    id params = @{
                  fAlert : textToSend,
                  fBadge : @"increment",
                  fSound : @"default",
                  @"recipientId": userId,
                  fPayload : @{
//                          fThumbnail : compressed,
                          fSenderId:    [User me].objectId,
                          fMessage:     textToSend,
                          fMessageId:   messageId,
                          },
                  };
    
    [PFCloud callFunctionInBackground:@"pushUserMessage" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
        }
        else {
            NSLog(@"PUSH SENT:%@", object);
        }
    }];
}

NSDictionary* __dictionaryForObject(PFObject* object, NSArray* fields)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [fields enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [object objectForKey:key];
        if (value) {
            [dictionary setObject:value forKey:key];
        }
    }];
    
    return dictionary;
}

void __addValue(NSMutableDictionary* dictionary, id key, id value) {
    if (value) {
        [dictionary setObject:value forKey:key];
    }
}

+ (void) sendChannelMessage:(NSString *)message
{
    User *me = [User me];
    
    id payload = [NSMutableDictionary dictionary];
    __addValue(payload, fSenderId, me.objectId);
    __addValue(payload, fNickname, me.nickname);
    __addValue(payload, fDesc, me.desc);
    __addValue(payload, fIntroduction, me.introduction);
    __addValue(payload, fAge, me.age);
    __addValue(payload, @"gender", me.genderTypeString);
    __addValue(payload, @"genderColor", NSStringFromUIColor(me.genderColor));
    __addValue(payload, fWhere, me.where);
    __addValue(payload, fMessage, message);
    __addValue(payload, fThumbnail, me.media.thumbnail);
    
    id params = @{
                  fChannel : @"Main",
                  fPayload : payload,
                  };
    [PFCloud callFunctionInBackground:@"sendMessageToChannel" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR SENDING PUSH:%@", error.localizedDescription);
        }
        else {
            NSLog(@"PUSH SENT:%@", object);
        }
    }];
}

+ (void) sendPushMessage:(NSString*)textToSend messageId:(id)messageId toUserId:(id)userId
{
    id params = @{
                  fChannel : userId,
                  fAlert : textToSend,
                  fBadge : @"increment",
                  fSound : @"default",
                  @"recipientId": userId,
                  fPayload : @{
                          //                          fThumbnail : compressed,
                          fSenderId:    [User me].objectId,
                          fMessage:     textToSend,
                          fMessageId:   messageId,
                          },
                  };
    
    [PFCloud callFunctionInBackground:@"sendMessageToUserChannel" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
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
    if (![self.chats writeToURL:self.chatFilePath
                     atomically:YES])
    {
        NSLog(@"Error saving chat file");
    }
}
*/


/*
+ (UNNotificationPresentationOptions)handlePushUserInfo:(id)info
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    
    UNNotificationPresentationOptions option;
    id pushType = userInfo[fPushType];
    [userInfo setObject:[NSDate date] forKey:fUpdatedAt];
    
    if ([pushType isEqualToString:@"pushTypeChannel"]) {
        option = UNNotificationPresentationOptionNone;
        [Queue addObject:userInfo];
        [Engine postNewChannelMessageNotification:userInfo];
    }
    else if ([pushType isEqualToString:@"pushTypeMessage"]){
        option = UNNotificationPresentationOptionSound;
        [Engine postNewUserMessageNotification:userInfo];
        [Engine setSystemBadge];
    }
    else {
        option = UNNotificationPresentationOptionNone;
    }
    
    return option;
}
*/

@end
