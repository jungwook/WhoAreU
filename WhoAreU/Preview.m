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

@interface PreviewUserCell : UICollectionViewCell
@property (nonatomic, strong) Media* media;
@property (nonatomic, copy) MediaBlock tapAction;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@end

@implementation PreviewUserCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.radius = 4.0f;
        self.clipsToBounds = YES;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
        
        self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activity.frame = frame;
        [self.activity startAnimating];
        [self addSubview:self.activity];
    }
    return self;
}

- (void)setMedia:(Media *)media
{
    _media = media;
    
    [self.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [S3File getImageFromFile:self.media.thumbnail imageBlock:^(UIImage *image) {
            __drawImage(image, self);
            [self.activity stopAnimating];
        }];
    }];
}

- (void) tapped:(id)sender
{
    if (self.tapAction) {
        self.tapAction(self.media);
    }
}

@end

@interface PreviewUser ()
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *media;
@property (nonatomic, weak) Media *presentedMedia;
@end

@implementation PreviewUser

- (instancetype)initWithUser:(User *)user
{
    CGRect bounds = mainWindow.bounds;
    self = [super initWithFrame:bounds];
    if (self) {
        _user = user;
        
        self.presentedMedia = nil;
    
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:   @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
        
        [self setupPreviewWithBounds:bounds];
        [self setupCollectionViewWithBounds:bounds];
        [self setupMedia];
        [self selectFirstMedia];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
    }
    return self;
}

- (void)setupPreviewWithBounds:(CGRect)bounds
{
    self.preview = [[UIView alloc] initWithFrame:bounds];
    self.preview.backgroundColor = [UIColor blackColor];
    [self addSubview:self.preview];
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activity.frame = bounds;
    [self.activity startAnimating];
    [self.preview addSubview:self.activity];
}

- (void)setupMedia
{
    self.media = [NSMutableArray array];
    if (self.user.media) {
        [self.user.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            [self.media insertObject:self.user.media atIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }];
    }
    
    [self.user.photos enumerateObjectsUsingBlock:^(Media * _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
        [photo fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            [self.media addObject:photo];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }];
    }];
}

- (void)selectFirstMedia
{
    Media *firstMedia = self.media.firstObject;
    if (firstMedia) {
        [self showPreview:[[PreviewMedia alloc] initWithMedia:firstMedia exitWithTap:NO]];
        self.presentedMedia = firstMedia;
    }
}

- (void)setupCollectionViewWithBounds:(CGRect) bounds
{
    const CGFloat collectionViewHeight = 80.0f;

    CGFloat h = CGRectGetHeight(bounds), w = CGRectGetWidth(bounds);
    CGRect collectionViewRect = CGRectMake(0, h-collectionViewHeight, w, collectionViewHeight);

    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.collectionView = [[UICollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:flow];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    [self.collectionView registerClass:[PreviewUserCell class] forCellWithReuseIdentifier:@"MediaCell"];

    [self addSubview:self.collectionView];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    self.frame = mainWindow.bounds;
    self.preview.frame = self.bounds;
    if (self.presentedMedia) {
        [self showPreview:[[PreviewMedia alloc] initWithMedia:self.presentedMedia exitWithTap:NO]];
    }
}

- (void)layoutSubviews
{
    const CGFloat collectionViewHeight = 80.0f;

    [super layoutSubviews];
    
    CGFloat h = CGRectGetHeight(self.bounds), w = CGRectGetWidth(self.bounds);
    CGRect collectionViewRect = CGRectMake(0, h-collectionViewHeight, w, collectionViewHeight);
    self.collectionView.frame = collectionViewRect;
    
    self.preview.frame = self.bounds;
    self.activity.frame = self.bounds;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 5.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    const CGFloat inset = 10.0f;
    CGFloat h = CGRectGetHeight(collectionView.bounds);
    return CGSizeMake(h-inset, h-inset);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.media.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
    
    cell.media = [self.media objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor blackColor];
    cell.tapAction = ^(Media *media) {
        [self showPreview:[[PreviewMedia alloc] initWithMedia:media exitWithTap:NO]];
        self.presentedMedia = media;
    };
    return cell;
}

- (void) showPreview:(PreviewMedia*)preview
{
    const CGFloat duration = 0.3f;

    PreviewMedia *subView = self.firstPreview;
    preview.alpha = 0.0f;
    [self.preview addSubview:preview];
    [UIView animateWithDuration:duration animations:^{
        subView.alpha = 0.0f;
        preview.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [subView killThisView];
    }];
}

- (void) tapped:(id)sender
{
    const CGFloat duration = 0.3f;

    [UIView animateWithDuration:duration animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self killThisView];
    }];
}

- (PreviewMedia*) firstPreview
{
    __block PreviewMedia* preview = nil;
    [self.preview.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([view isKindOfClass:[PreviewMedia class]]) {
            preview = view;
            *stop = YES;
        }
    }];
    return preview;
}

- (void) killThisView
{
    [self.preview.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([view isKindOfClass:[PreviewMedia class]]) {
            PreviewMedia *pm = (PreviewMedia*) view;
            [pm killThisView];
        }
    }];
    [self removeFromSuperview];
}

- (void)dealloc
{
    __LF
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end

@interface PreviewMedia () <UIScrollViewDelegate>
@property (strong, nonatomic) Media* media;
@property (strong, nonatomic) CenterScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView* playerView;
@property (nonatomic) CGFloat zoom;
@property (nonatomic) BOOL videoAlive, exitsWithTap;
@property (strong, nonatomic) UILabel *real;
@end

@implementation PreviewMedia

- (instancetype)initWithMedia:(Media *)media exitWithTap:(BOOL)taps
{
    switch (media.type) {
        case kMediaTypePhoto: {
            self = [self initWithImageFile:media.media exitWithTap:(BOOL)taps];
        }
            
            break;
        case kMediaTypeVideo:
        {
            self = [self initWithVideoURL:media.media exitWithTap:(BOOL)taps];
        }
            break;
    }
    if (self) {
        _media = media;
        self.real = [UILabel new];
        self.real.textColor = [UIColor whiteColor];
        self.real.text = media.source == kSourceTaken ? @"From Camera" : @"From Library";
        [self.real sizeToFit];
        
        [self addSubview:self.real];
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSString*)url exitWithTap:(BOOL)taps
{
    self = [super initWithFrame:mainWindow.frame];
    if (self) {
        self.exitsWithTap = taps;
        self.videoAlive = NO;
        [self initializeVideoWithURL:[NSURL URLWithString:[S3LOCATION stringByAppendingString:url]]];
    }
    return self;
}

- (instancetype) initWithImageFile:(id)mediaFile exitWithTap:(BOOL)taps
{
    self = [super initWithFrame:mainWindow.frame];
    if (self) {
        self.exitsWithTap = taps;

        CGRect frame = self.frame, bounds = self.bounds;
        self.scrollView = [[CenterScrollView alloc] initWithFrame:frame];
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:bounds];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:self.imageView];
        
        // Tap gesture recognizers
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        
        if (self.exitsWithTap) {
            [self.scrollView addGestureRecognizer:singleTap];
        }
        [self.scrollView addGestureRecognizer:doubleTap];
        [S3File getDataFromFile:mediaFile dataBlock:^(NSData *data) {
            UIImage *image = [UIImage imageWithData:data];
            NSDictionary *metrics = @{@"height" : @(image.size.height), @"width" : @(image.size.width)};
            NSDictionary *views = @{@"imageView":self.imageView};
            [self.scrollView removeConstraints:self.scrollView.constraints];
            [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(height)]|" options:kNilOptions metrics:metrics views:views]];
            [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(width)]|" options:kNilOptions metrics:metrics views:views]];
            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            
            self.imageView.image = image;
            [self initZoomWithImage:image];
        }];
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
    
    self.playerView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.playerView];
    [self.playerView.layer addSublayer:self.playerLayer];
    
    if (self.exitsWithTap) {
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToKill:)]];
    }
}

- (void)tapToKill:(id)sender
{
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
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        switch (self.playerItem.status) {
            case AVPlayerItemStatusReadyToPlay: {
                CGSize size = self.playerItem.presentationSize;
                CGFloat w = size.width, h=size.height;
                CGRect bounds = self.bounds;
                CGFloat W = CGRectGetWidth(bounds), H = CGRectGetHeight(bounds);
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
    
    [self.imageView removeFromSuperview];
    [self.scrollView removeFromSuperview];
    [self.playerView removeFromSuperview];
    
    self.scrollView = nil;
    self.imageView = nil;
    self.playerItem = nil;
    self.player = nil;
    self.playerLayer = nil;
    self.playerView = nil;
    
    [self removeFromSuperview];
}

- (void) dealloc
{
    __LF
}

- (void)layoutSubviews
{
    __LF
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat lw = CGRectGetWidth(self.real.bounds);
    CGFloat lh = CGRectGetHeight(self.real.bounds);
    CGFloat inset = 10;
    
    self.real.frame = CGRectMake(w-lw-inset, h-lh-inset, lw, lh);
    self.real.frame = CGRectMake(inset, inset*1.5, lw, lh);
}

- (void) singleTap:(id)sender {
    [self killThisView];
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
    float minZoom = MIN(self.bounds.size.width / image.size.width, self.bounds.size.height / image.size.height);
    if (minZoom > 1) return;
    
    self.scrollView.minimumZoomScale = minZoom;
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.zoomScale = minZoom;
    self.zoom = minZoom;
}

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}
//
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.zoom = scale;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
