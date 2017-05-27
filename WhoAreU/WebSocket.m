//
//  WebSocket.m
//  Pods
//
//  Created by 한정욱 on 2017. 5. 17..
//
//

#import "WebSocket.h"
#import "SRWebSocket.h"
#import "ObjectIdStore.h"
#import "MessageCenter.h"

#define TIMERHANDLER_INTERVAL 5.0f

@interface WebSocket() <SRWebSocketDelegate>
@property (strong, nonatomic) SRWebSocket *socket;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) BOOL isAlive;
@property (nonatomic) BOOL isActive;
@property (nonatomic, readonly) TimerBlock timerHandler;
@property (nonatomic, strong) NSMutableArray *packets;
@end

@implementation WebSocket

+ (instancetype)newWithId:(id)userId
{
    return [[WebSocket alloc] initWithId:userId];
    
}

- (void) send:(id)packet
{
    if (self.isAlive) {
        [self.socket send:packet];
    }
    else {
        [self.packets addObject:packet];
    }
}

- (void) dealloc
{
    __LF
    RNOTIF(UIApplicationWillResignActiveNotification);
    RNOTIF(UIApplicationDidBecomeActiveNotification);
}

- (instancetype)initWithId:(id)userId
{
    self = [super init];
    if (self) {
        ANOTIF(UIApplicationWillResignActiveNotification, @selector(notificationApplicationWillResignActive:));
        ANOTIF(UIApplicationDidBecomeActiveNotification, @selector(notificationApplicationDidBecomeActive:));
        
        _userId = userId;
        self.isAlive = NO;
        self.isActive = YES;
        self.packets = [NSMutableArray new];
        [self initializeSocket];
        [self initializeTimer];
    }
    return self;
}

- (void) initializeTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMERHANDLER_INTERVAL repeats:YES block:self.timerHandler];
}

- (void) initializeSocket
{
    _socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:WSLOCATION]];
    [self.socket setDelegate:self];
    [self.socket open];
    
    self.isAlive = NO;
}

- (TimerBlock) timerHandler
{
    return ^(NSTimer *timer) {
        if (self.isActive == YES && self.socket == nil) {
            [self initializeSocket];
        }
        else if (self.socket.readyState == SR_CLOSED) {
            [self initializeSocket];
        }
        else if (self.socket.readyState == SR_CLOSING) {
            [self.socket close];
        }
    };
}

- (void)notificationApplicationWillResignActive:(NSNotification*)notification
{
    __LF
    if (self.isActive == YES) {
        self.isActive = NO;
        [self stopTimer];
        [self.socket close];
    }
}

- (void)notificationApplicationDidBecomeActive:(NSNotification*)notification
{
    __LF
    if (self.isActive == NO) {
        self.isActive = YES;
        [self initializeSocket];
        [self initializeTimer];
    }
}

- (void) stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    __LF
    NSString *message = [NSString stringWithFormat:@"%@ logged in", [User me].nickname];
    
    if (self.isActive) {
        self.isAlive = YES;
        id packet = @{
                      fOperation : @"registration",
                      fId        : self.userId,
                      fWhen      : [NSDate date].stringUTC,
                      fMe        : [User me].simpleDictionary,
                      fChannel   : [User me].channel,
                      fMessage   : message,
                      };
        
        [self send:packet];
        
        [MessageCenter sayHiToNearbyUsers];
        [MessageCenter sayMessageToNearbyUsers:@"Hi"];
        
        if (self.packets.count>0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"RE-sending %ld backlog packets", self.packets.count);
                while (self.packets.count > 0) {
                    id packet = [self.packets firstObject];
                    [self send:packet];
                    [self.packets removeObjectAtIndex:0];
                }
            });
        }
    }
    else {
        self.isAlive = NO;
        [self.socket close];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error
{
    __LF
    NSLog(@"FAILED [%s]:%@", __func__, error.localizedDescription);
    if (webSocket.data && [webSocket.data isKindOfClass:[NSDictionary class]]) {
        [self.packets addObject:webSocket.data];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    __LF
    NSLog(@"CLOSED [%ld]:%@ - %ld[%@]", code, reason, webSocket.readyState, wasClean ? @"YES" : @"NO");
    
    __alert(@"System Warning", @"Chatserver is down.\nMessages will be backlogged", nil, nil, nil);

    self.isAlive = NO;
    self.socket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    __LF

    NSError *error=nil;
    
    if ([message isKindOfClass:[NSString class]]) {
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) {
            NSLog(@"ERROR[%s]:%@", __func__, error.localizedDescription);
            return;
        }
        else {
            NSLog(@"MESSAGE:%@", dictionary);
            [MessageCenter handlePushUserInfo:dictionary];
        }
    }
    else if ([message isKindOfClass:[NSData class]]) {
        NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:message options:kNilOptions error:&error];
        if (error) {
            NSLog(@"ERROR[%s]:%@", __func__, error.localizedDescription);
            return;
        }
        else {
            NSLog(@"MESSAGE:%@", dictionary);
            [MessageCenter handlePushUserInfo:dictionary];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload
{
    __LF
}
@end
