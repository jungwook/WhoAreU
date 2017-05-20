//
//  MediaView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 11..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaView.h"
#import "CenterScrollView.h"
#import "S3File.h"
#import "IndentedLabel.h"

@interface MediaView() <UIScrollViewDelegate>
// Media type as image...
@property (nonatomic, strong) CenterScrollView *scrollView;
@property (nonatomic, strong) UIImageView* imageView;

// Media type as video...
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView* playerView;

@property (nonatomic) BOOL videoAlive;
@property (nonatomic, strong) UILabel *source;

@end

@implementation MediaView

- (instancetype)init
{
    CGRect frame = mainWindow.bounds;
    
    self = [super initWithFrame:frame];
    if (self) {
        self.collectionViewHeightOffset = 8.0f;
        [self setupSubviewsWithFrame:frame];
    }
    return self;
}

- (void) setupSubviewsWithFrame:(CGRect)frame
{
    self.playerView = [[UIView alloc] initWithFrame:frame];
    [self addSubview:self.playerView];
    
    self.scrollView = [[CenterScrollView alloc] initWithFrame:frame];
    self.scrollView.delegate = self;
    
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;

    [self.scrollView addSubview:self.imageView];
    [self addSubview:self.scrollView];
    
    
    self.source = [UILabel new];
    self.source.textColor = [UIColor whiteColor];
    self.source.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.source.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.source];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = mainWindow.bounds;
    self.frame = frame;
    self.scrollView.frame = frame;
    self.playerView.frame = frame;
    
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat lw = CGRectGetWidth(self.source.bounds);
    CGFloat lh = CGRectGetHeight(self.source.bounds);
    CGFloat inset = 8;
    
    self.source.frame = CGRectMake(w-lw-inset, h-lh-inset-self.collectionViewHeightOffset, lw, lh);
    self.source.frame = CGRectMake(inset, h-lh-self.collectionViewHeightOffset, lw, lh);
    
    [self centerPlayerLayer];
}

- (void) centerPlayerLayer
{
    CGSize size = self.playerItem.presentationSize;
    CGFloat w = size.width, h=size.height;
    if ( w > 0) {
        CGRect bounds = self.bounds;
        CGFloat W = CGRectGetWidth(bounds), H = CGRectGetHeight(bounds);
        CGFloat fW = W, fH = h * W / w;
        
        CGRect playerFrame = CGRectMake(0, (H-fH)/2, fW, fH);
        
        self.playerLayer.frame = playerFrame;
    }
}

- (void)setMedia:(Media *)media
{
    _media = media;
    [self.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        switch (self.media.type) {
            case kMediaTypePhoto:
                [self setupImageView];
                break;
            default:
            case kMediaTypeVideo:
                [self setupPlayerView];
                break;
        }
        self.source.text = media.source == kSourceTaken ? @"From Camera" : @"From Library";
        [self.source sizeToFit];
    }];
}

- (void)setupImageView
{
    const ImageBlock loadImageAction = ^(UIImage *image) {
        NSDictionary *metrics = @{@"height" : @(image.size.height), @"width" : @(image.size.width)};
        NSDictionary *views = @{@"imageView":self.imageView};
        
        [self.scrollView removeConstraints:self.scrollView.constraints];
        [self.imageView removeConstraints:self.imageView.constraints];
        
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(height)]|" options:kNilOptions metrics:metrics views:views]];
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(width)]|" options:kNilOptions metrics:metrics views:views]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        float minZoom = MIN(MIN(self.bounds.size.width / image.size.width, self.bounds.size.height / image.size.height), 1.0f);
        self.scrollView.minimumZoomScale = minZoom;
        self.scrollView.maximumZoomScale = 2.0;
        self.scrollView.zoomScale = minZoom;
        
        self.imageView.image = image;
    };
    
    
    
    [self dependingOn:(self.playerItem != nil) hideView:self.playerView action:nil];
    [self dependingOn:(self.imageView.image) hideView:self.scrollView action:^{
        [S3File getImageFromFile:self.media.media imageBlock:^(UIImage *image) {
            loadImageAction(image);
            [self slowlyShowView:self.scrollView completion:nil];
        }];
    }];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

-(void) setupPlayerView
{
    const VoidBlock loadVideoAction = ^() {
        self.videoAlive = NO;
        NSURL *url = [NSURL URLWithString:[S3LOCATION stringByAppendingString:self.media.media]];
        
        [self killPlayerItem];
        
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
        
        [self.playerView.layer addSublayer:self.playerLayer];
    };
    
    [self dependingOn:(self.playerItem != nil) hideView:self.playerView action:^{
        loadVideoAction();
    }];
    
    [self dependingOn:(self.imageView.image) hideView:self.scrollView action:nil];

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
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        switch (self.playerItem.status) {
            case AVPlayerItemStatusReadyToPlay: {
                [self centerPlayerLayer];
                [self.playerLayer removeAllAnimations];
                self.videoAlive = YES;
                [self slowlyShowView:self.playerView completion:^(BOOL value) {
                    [self.player play];
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

- (void) killPlayerItem
{
    __LF
    self.videoAlive = NO;
    if (self.playerItem) {
        [self.player pause];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    [self.playerLayer removeFromSuperlayer];
    self.playerItem = nil;
    self.player = nil;
    self.playerLayer = nil;
}

- (void)removeFromSuperview
{
    __LF
    [self killPlayerItem];
    
    [self.imageView removeFromSuperview];
    [self.scrollView removeFromSuperview];
    [self.playerView removeFromSuperview];
    [self.source removeFromSuperview];
    [super removeFromSuperview];
}

-(void)dealloc
{
    __LF
    [self killPlayerItem];

    [self.imageView removeFromSuperview];
    [self.scrollView removeFromSuperview];
    [self.playerView removeFromSuperview];
    [self.source removeFromSuperview];
    [super removeFromSuperview];
}

- (void) dependingOn:(BOOL)condition
            hideView:(UIView*)view
              action:(VoidBlock)handler
{
    if (condition) {
        [self slowlyHideView:view completion:^(BOOL value) {
            if (handler) {
                handler();
            }
        }];
    }
    else {
        if (handler) {
            handler();
        }
    }
}

- (void)slowlyHideView:(UIView*)view completion:(BOOLBlock)completion
{
    const CGFloat duration = 0.3f;
    [UIView animateWithDuration:duration animations:^{
        view.alpha = 0.0f;
    } completion:completion];
}

- (void)slowlyShowView:(UIView*)view completion:(BOOLBlock)completion
{
    const CGFloat duration = 0.3f;
    [UIView animateWithDuration:duration animations:^{
        view.alpha = 1.0f;
    } completion:completion];
}

@end
