//
//  Preview.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 2..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Preview.h"
#import "S3File.h"

@interface CenterScrollView : UIScrollView
@end

@implementation CenterScrollView

-(void)layoutSubviews
{
    [super layoutSubviews];
    UIView* v = [self.delegate viewForZoomingInScrollView:self];
    CGFloat svw = self.bounds.size.width;
    CGFloat svh = self.bounds.size.height;
    CGFloat vw = v.frame.size.width;
    CGFloat vh = v.frame.size.height;
    CGFloat off = 64.0f;
    CGRect f = v.frame;
    
    off = 0.0f;
    
    if (vw < svw)
        f.origin.x = (svw - vw) / 2.0;
    else
        f.origin.x = 0;
    
    if (vh < svh)
        f.origin.y = (svh - vh) / 2.0 - off;
    else
        f.origin.y = -off;
    v.frame = f;
}

@end

@interface Preview () <UIScrollViewDelegate>
@property (strong, nonatomic) CenterScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView* playerView;
@property (nonatomic) CGFloat zoom;
@property (nonatomic) BOOL videoAlive;
@property (weak, nonatomic) Media* media;
@end

@implementation Preview

- (instancetype)initWithVideoURL:(NSString*)url
{
    self = [super init];
    if (self) {
        self.videoAlive = NO;
        [self initializeVideoWithURL:[NSURL URLWithString:[S3LOCATION stringByAppendingString:url]]];
        NSLog(@"Playing:%@", [S3LOCATION stringByAppendingString:url]);
    }
    return self;
}

- (void) initializeVideoWithURL:(NSURL*)url
{
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
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
    
    self.view.backgroundColor = [UIColor blackColor];
    self.playerView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];
    [self.playerView.layer addSublayer:self.playerLayer];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToKill:)]];
}

- (void)tapToKill:(id)sender
{
    __LF
    [self killThisView];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    __LF
    [self.player seekToTime:kCMTimeZero];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoAlive = YES;
        [self.player play];
    });
}

- (void)playerItemStalled:(NSNotification *)notification
{
    __LF
    [self restartPlayingIfLikelyToKeepUp];
}

- (void) restartPlayingIfLikelyToKeepUp
{
    __LF
    
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
    __LF
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        switch (self.playerItem.status) {
            case AVPlayerItemStatusReadyToPlay: {
                CGSize size = self.playerItem.presentationSize;
                CGFloat w = size.width, h=size.height;
                CGFloat W = CGRectGetWidth(self.view.bounds), H = CGRectGetHeight(self.view.bounds);
                CGFloat fW = W, fH = h * W / w;
                
                self.playerView.frame = CGRectMake(0, (H-fH)/2, fW, fH);
                self.playerLayer.frame = self.playerView.bounds;
                [self.playerLayer removeAllAnimations];
                // if source == captured.. add subview
                
                self.videoAlive = YES;
                [self.player play];
            }
                break;
            case AVPlayerItemStatusFailed:
            case AVPlayerItemStatusUnknown:
            default:
                self.videoAlive = NO;
                [self killThisView];
                break;
        }
    }
}

- (void) killThisView
{
    if (self.playerItem) {
        [self.player pause];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    
    [self killAllSubViews];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) killAllSubViews
{
    [self.imageView removeFromSuperview];
    [self.scrollView removeFromSuperview];
    [self.playerView removeFromSuperview];
    
    self.scrollView = nil;
    self.imageView = nil;
    self.playerItem = nil;
    self.player = nil;
    self.playerLayer = nil;
    self.playerView = nil;

}

- (void) dealloc
{
    __LF
    [self killAllSubViews];
}

- (instancetype)initWithMedia:(Media *)media
{
    _media = media;
    switch (self.media.type) {
        case kMediaTypePhoto: {
            self = [super init];
            if (self) {
                self.scrollView = [[CenterScrollView alloc] initWithFrame:self.view.frame];
                self.scrollView.delegate = self;
                self.scrollView.backgroundColor = [UIColor blackColor];
                [self.view addSubview:self.scrollView];
                
                self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
                self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
                [self.scrollView addSubview:self.imageView];
                
                // Tap gesture recognizers
                
                UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
                doubleTap.numberOfTapsRequired = 2;
                
                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
                
                [self.scrollView addGestureRecognizer:doubleTap];
                [self.scrollView addGestureRecognizer:singleTap];
                [S3File getDataFromFile:self.media.media dataBlock:^(NSData *data) {
                    UIImage *image = [UIImage imageWithData:data];
                    NSDictionary *metrics = @{@"height" : @(image.size.height), @"width" : @(image.size.width)};
                    NSDictionary *views = @{@"imageView":self.imageView};
                    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(height)]|" options:kNilOptions metrics:metrics views:views]];
                    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(width)]|" options:kNilOptions metrics:metrics views:views]];
                    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    
                    self.imageView.image = image;
                    [self initZoomWithImage:image];
                }];
            }
            return self;
        }
            
            break;
        case kMediaTypeVideo:
        {
            return [self initWithVideoURL:self.media.media];
        }
            break;
            
        default:
            break;
    }
}

- (instancetype)initWithImage:(UIImage*)image
{
    self = [super init];
    if (self) {
        self.scrollView = [[CenterScrollView alloc] initWithFrame:self.view.frame];
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.scrollView];

        self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:self.imageView];

        NSDictionary *metrics = @{@"height" : @(image.size.height), @"width" : @(image.size.width)};
        NSDictionary *views = @{@"imageView":self.imageView};
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(height)]|" options:kNilOptions metrics:metrics views:views]];
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(width)]|" options:kNilOptions metrics:metrics views:views]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;

        self.imageView.image = image;
        
        // Tap gesture recognizers
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        
        [self.scrollView addGestureRecognizer:doubleTap];
        [self.scrollView addGestureRecognizer:singleTap];
        
        // initialize zoom factors for image
        
        [self initZoomWithImage:image];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) singleTap:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) doubleTap:(id)sender {
    static CGFloat prev = 1;
    
    CGFloat zoom = self.scrollView.zoomScale;
    [UIView animateWithDuration:0.1 animations:^{
        self.scrollView.zoomScale = prev;
    }];
    prev = zoom;
}

- (void) initZoomWithImage:(UIImage*)image
{
    float minZoom = MIN(self.view.bounds.size.width / image.size.width, self.view.bounds.size.height / image.size.height);
    if (minZoom > 1) return;
    
    self.scrollView.minimumZoomScale = minZoom;
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.zoomScale = minZoom;
    self.zoom = minZoom;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.zoom = scale;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
