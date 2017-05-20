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
    __LF
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
    
    PNOTIF(kNotificationSystemInitialized, nil);
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
