//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    kSimulatorStatusUnknown = 0,
    kSimulatorStatusSimulator,
    kSimulatorStatusDevice,
} SimulatorStatus;

@interface Counter : NSObject
@property (strong, nonatomic) NSMutableDictionary *counters;
- (id) setCount:(NSUInteger)count completion:(VoidBlock)handler;
- (void) decreaseCount:(id)counterId;
@end

@interface Engine : NSObject
@property (nonatomic) BOOL initialized;
@property (nonatomic) SimulatorStatus simulatorStatus;
+ (void) initializeSystems;
+ (CLLocationDirection) heading;
+ (BOOL) headingAvailable;
@end
