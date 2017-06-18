//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Counter : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic, copy) VoidBlock completionHandler;

+ (instancetype) counterWithCount:(NSUInteger)count completion:(VoidBlock)handler;
- (void) setCount:(NSUInteger)count completion:(VoidBlock)handler;
- (void) decreaseCount;
@end


typedef enum : NSUInteger {
    kSimulatorStatusUnknown = 0,
    kSimulatorStatusSimulator,
    kSimulatorStatusDevice,
} SimulatorStatus;

@interface Engine : NSObject
@property (nonatomic) BOOL initialized;
@property (nonatomic) SimulatorStatus simulatorStatus;
+ (void) initializeSystems;
+ (CLLocationDirection) heading;
+ (BOOL) headingAvailable;
@end
