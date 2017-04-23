//
//  Engine.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Engine.h"
#include "TargetConditionals.h"


@interface Engine() <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation* currentLocation;
@property (strong, nonatomic) NSObject *lock;
@property (weak, nonatomic) User *me;
@property (nonatomic) BOOL simulator;
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
    Engine *engine = [Engine new];
    
    [engine initLocationServices];
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
    
    self.simulator = NO;
#ifdef TARGET_OS_SIMULATOR
    self.simulator = YES;
    NSLog(@"Working with simulator");
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
