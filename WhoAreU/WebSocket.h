//
//  WebSocket.h
//  Pods
//
//  Created by 한정욱 on 2017. 5. 17..
//
//

#import <Foundation/Foundation.h>

typedef void(^TimerBlock)(NSTimer *);

@interface WebSocket : NSObject
@property (readonly) id userId;

+ (instancetype)newWithId:(id)userId;
- (void) send:(id)packet;
@end
