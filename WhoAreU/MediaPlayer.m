//
//  MediaPlayer.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaPlayer.h"

@interface MediaPlayer()
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) VolumeIcon *volume;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic) BOOL videoAlive;
@property (nonatomic, weak) NSString* media;
@end

@implementation MediaPlayer

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
        self.userInteractionEnabled = YES;
        self.playerView = [UIView new];
        self.volume = [VolumeIcon new];
        self.volume.barColor = [UIColor whiteColor];
        [self addSubview:self.playerView];
        [self addSubview:self.volume];
        
        [self.volume setHidden:NO];
        VoidBlock action = ^() {
            self.muted = !self.muted;
        };
        self.volume.tappedAction = action;
    }
    return self;
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    
    self.player.muted = muted;
    self.volume.muted = muted;
}

- (void)setMedia:(NSString *)media attachOnView:(UIView*)view
{
    _media = media;
    
    if (media) {
        NSURL *url = [NSURL URLWithString:[S3LOCATION stringByAppendingString:media]];
        NSLog(@"URL:%@", url.absoluteString);
        [self killPlayerItem];
        [self setupPlayerViewWithURL:url];
        [view setUserInteractionEnabled:YES];
        [view addSubview:self];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    self.frame = self.superview.bounds;
    
    CGFloat h = CGRectGetHeight(self.bounds), inset = 8, width = 30, height = 20;
    
    self.playerView.frame = self.bounds;
    self.volume.frame = CGRectMake(inset, h - height - inset, width, height);
    self.playerLayer.frame = self.bounds;
    [self.playerView.layer addSublayer:self.playerLayer];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self centerPlayerLayer];
}

- (void)dealloc
{
    __LF
}

-(void) stopCurrentPlayback
{
    [self killPlayerItem];
}

-(void) setupPlayerViewWithURL:(NSURL*)url
{
    self.videoAlive = NO;
    self.alpha = 0;
    
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.muted = YES;
    
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:self.playerItem];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:kCMTimeZero];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoAlive = YES;
        [self.player play];
    });
}

- (void)playerItemStalled:(NSNotification *)notification
{
    [self restartPlayingIfLikelyToKeepUp];
}

- (void) restartPlayingIfLikelyToKeepUp
{
    if (self.videoAlive == NO) {
        return;
    }
    
    if (self.playerItem.playbackLikelyToKeepUp) {
        self.videoAlive = YES;
        [self.player play];
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self restartPlayingIfLikelyToKeepUp];
        });
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        switch (self.playerItem.status) {
            case AVPlayerItemStatusReadyToPlay: {
                [self centerPlayerLayer];
                [self.playerLayer removeAllAnimations];
                self.videoAlive = YES;
                [self slowlyShowView:YES completion:^(BOOL value) {
                    [self.player play];
                    [self.volume setAnimating:YES];
                }];
            }
                break;
            case AVPlayerItemStatusFailed:
            case AVPlayerItemStatusUnknown:
            default:
                self.videoAlive = NO;
                [self killPlayerItem];
                break;
        }
    }
}

- (void) centerPlayerLayer
{
    CGSize size = self.playerItem.presentationSize;
    CGFloat w = size.width, h=size.height;
    if ( w > 0) {
        CGFloat width = CGRectGetWidth(self.bounds), height = CGRectGetHeight(self.bounds);
        CGFloat fW = width, fH = h * width / w;
        CGRect playerFrame = CGRectMake(0, (height-fH)/2, fW, fH);
        self.playerLayer.frame = playerFrame;
    }
}

- (void) killPlayerItem
{
    self.videoAlive = NO;
    if (self.playerItem) {
        [self slowlyShowView:NO completion:^(BOOL value) {
            [self.volume setAnimating:NO];
            [self.player pause];
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
            [self.playerLayer removeFromSuperlayer];
            self.playerItem = nil;
            self.player = nil;
            self.playerLayer = nil;
            [self removeFromSuperview];
        }];
    }
    else {
        [self.playerLayer removeFromSuperlayer];
        self.playerItem = nil;
        self.player = nil;
        self.playerLayer = nil;
        [self removeFromSuperview];
    }
}

- (void)slowlyShowView:(BOOL)show completion:(BOOLBlock)completion
{
    const CGFloat duration = 0.3f;
    [UIView animateWithDuration:duration animations:^{
        self.alpha = show;
        self.volume.hidden = !show;
    } completion:completion];
}

@end

#define numBars 5
#define numSteps 10

@interface VolumeIcon()
{
    UIView      *bars[numBars];
    NSTimer     *timers[numBars];

    NSUInteger  steps[numBars];
    CGRect      barFrames[numBars];
    
    CAGradientLayer *gradients[numBars];
    NSArray     *mutedBarColors, *barColors;
}
@property (nonatomic, readonly) CGFloat barWidth;
@property (nonatomic, readonly) CGFloat barHeight;
@property (nonatomic, readonly) CGFloat barOffset;
@property (nonatomic, readonly) CGFloat barSpacing;
@property (nonatomic, readonly) CGFloat barInterimSpacing;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIView *tapArea;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation VolumeIcon

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.clipsToBounds = NO;
    self.backgroundColor = [UIColor clearColor];
    self.barColor = [UIColor whiteColor];
    
    self.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
    
    barColors = @[
                  (id) [UIColor yellowColor].CGColor,
                  (id) [UIColor redColor].CGColor,
                  ];
    
    mutedBarColors = @[
                       (id) [UIColor colorWithWhite:0.6 alpha:0.8].CGColor,
                       (id) [UIColor colorWithWhite:0.3 alpha:0.8].CGColor,
                       ];
    
    for (int i=0; i<numBars; i++) {
        UIView *bar = [UIView new];
        bar.backgroundColor = self.barColor;
        
        [self addSubview:bar];
        bars[i] = bar;
    }
    
    self.tapArea = [UIView new];
    [self addSubview:self.tapArea];
    
    [self.tapArea addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}

- (void) startDisplayLink:(BOOL)start
{
    if (start) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay)];
        self.displayLink.preferredFramesPerSecond = 5.0f;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    else {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void) updateDisplay
{
    static NSDate *prevDate = nil;

    NSDate *now = [NSDate date];
    if (prevDate == nil) {
        for (int i=0; i<numBars; i++) {
            steps[i] = 0;
        }
        prevDate = now;
    }
    
    if ([now timeIntervalSinceDate:prevDate] > 0.2 ) {
        prevDate = now;
        self.action();
    }
}

- (void)tapped:(id)sender
{
    if (self.tappedAction) {
        self.tappedAction();
    }
}

- (CAShapeLayer*) equalizerMask
{
    CAShapeLayer *mask = [CAShapeLayer new];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (int i=0; i<numBars; i++) {
        for (int j=0; j<numSteps; j++) {
            UIBezierPath *box = [UIBezierPath bezierPathWithRoundedRect:[self rectAtIndex:i power:j] cornerRadius:2.f];
            [path appendPath:box];
        }
    }
    mask.path = path.CGPath;
    
    return mask;
}

- (void)setAnimating:(BOOL)animating
{
    _animating = animating;
    [self startDisplayLink:animating];
}

- (CGFloat) barOffset
{
    return 1.0f;
}

- (CGRect) rectAtIndex:(NSUInteger)index power:(NSUInteger)power
{
    CGFloat x = self.barOffset + index*(self.barWidth+self.barInterimSpacing);
    CGFloat y = self.barOffset + power*(self.barHeight+self.barSpacing);
    
    return CGRectMake(x, y, self.barWidth, self.barHeight);
}

- (CGRect) rectToBottomAtIndex:(NSUInteger)index power:(NSUInteger)power
{
    CGFloat h = CGRectGetHeight(self.bounds);
    
    CGFloat x = self.barOffset + index*(self.barWidth + self.barInterimSpacing);
    CGFloat y = self.barOffset + power*(self.barHeight + self.barSpacing);
    
    return CGRectMake(x, y, self.barWidth, h-y);
}

- (void)layoutSubviews
{
    static CGRect prevFrame;
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(prevFrame, self.bounds)) {
        prevFrame = self.bounds;
        self.layer.mask = self.equalizerMask;
        for (int i=0; i<numBars; i++) {
            barFrames[i] = [self rectToBottomAtIndex:i power:0];
            bars[i].frame = barFrames[i];
            [bars[i].layer addSublayer:[self gradientAtIndex:i]];
        }
    }
    
    self.tapArea.frame = self.bounds;
}

- (CAGradientLayer*)gradientAtIndex:(NSUInteger)index
{
    CAGradientLayer *gradient = [CAGradientLayer new];
    gradient.frame = bars[index].bounds;
    gradient.colors = mutedBarColors;
    gradients[index] = gradient;
    return gradient;
}

- (void(^)())action
{
    return ^() {
        short p;

        for (int i=0; i<numBars-1; i++) {
            steps[i] = steps[i+1];
        }

        do {
            p = arc4random_uniform(numSteps+1);
        } while (p == steps[numBars-1]);

        steps[numBars-1] = p;

        for (int i=0; i<numBars; i++) {
            bars[i].frame = barFrames[i];
            CGRect frame = [self rectToBottomAtIndex:i power:steps[i]];
            [UIView animateWithDuration:0.15 animations:^{
                bars[i].frame = frame;
                barFrames[i] = frame;
            }];
        }
    };
}

- (CGFloat)barWidth
{
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat interim = w*0.05;
    CGFloat offset = 1.f;
    CGFloat width = (w-2*offset-interim*(numBars-1))/numBars;
    
    return width;
}

- (CGFloat) barHeight
{
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat space = h*0.05;
    CGFloat offset = 1.f;
    CGFloat height = (h-2*offset-space*(numSteps-1))/numSteps;
    
    return height;
}

- (CGFloat) barInterimSpacing
{
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat interim = w*0.05;
    return interim;
}

- (CGFloat) barSpacing
{
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat space = h*0.05;
    
    return space;
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    
    for (int i=0; i<numBars; i++) {
        gradients[i].colors = muted ? mutedBarColors : barColors;
    }

    self.backgroundColor = muted ? [UIColor colorWithWhite:0.4 alpha:0.4] : [UIColor colorWithWhite:0.8 alpha:0.4];
}

@end

