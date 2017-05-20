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

#define TIMERHANDLER_INTERVAL 10.0f

@interface WebSocket() <SRWebSocketDelegate>
@property (strong, nonatomic) SRWebSocket *socket;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) BOOL isAlive;
@property (nonatomic, readonly) TimerBlock timerHandler;
@end

@implementation WebSocket

+ (instancetype)newWithId:(id)userId
{
    return [[WebSocket alloc] initWithId:userId];
    
}
- (void) send:(id)packet
{
    [self.socket send:packet];
}

- (void) dealloc
{
    __LF
    RNOTIF(UIApplicationWillEnterForegroundNotification);
    RNOTIF(UIApplicationWillResignActiveNotification);
}

- (instancetype)initWithId:(id)userId
{
    ANOTIF(UIApplicationWillResignActiveNotification, @selector(notificationApplicationWillResignActive:));
    ANOTIF(UIApplicationWillEnterForegroundNotification, @selector(notificationApplicationWillEnterForeground:));
    
    self = [super init];
    if (self) {
        __LF
        _userId = userId;
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
    SRWebSocket *socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:WSLOCATION]];
    [socket setDelegate:self];
    [socket open];
    self.isAlive = NO;
}

- (TimerBlock) timerHandler
{
    return ^(NSTimer *timer) {
        if (self.socket && self.isAlive == NO) {
            [self.socket close];
            self.socket = nil;
        } else if (self.socket && self.isAlive == YES) {
            // need to get pong back within 2.0f seconds.
            self.isAlive = NO;
            if (self.socket.readyState == SR_OPEN) {
                [self.socket sendPing:nil];
            }
        } else if (self.socket == nil) {
            [self initializeSocket];
        }
    };
}

- (void)notificationApplicationWillResignActive:(NSNotification*)notification
{
    __LF
    [self.timer invalidate];
    self.timer = nil;
    [self.socket close];
}

- (void)notificationApplicationWillEnterForeground:(NSNotification*)notification
{
    __LF
    [self initializeSocket];
    [self initializeTimer];
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload
{
    self.isAlive = YES;
    self.socket = webSocket;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    __LF
    self.isAlive = YES;
    self.socket = webSocket;
    id packet = @{
                  @"operation" : @"registration",
                  @"id" : self.userId,
                  };
    
    [self.socket send:packet];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    __LF
    NSLog(@"ERROR[%s]:%@", __func__, error.localizedDescription);
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    __LF
    NSLog(@"CLOSED [%ld]:%@", code, reason);
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

@end
