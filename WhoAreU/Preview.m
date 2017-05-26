//
//  Preview.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 2..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Preview.h"
#import "S3File.h"
#import "CenterScrollView.h"
#import "MediaView.h"

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
    
    [S3File getImageFromFile:self.media.thumbnail imageBlock:^(UIImage *image) {
        __drawImage(image, self);
        [self.activity stopAnimating];
    }];
}

- (void) tapped:(id)sender
{
    if (self.tapAction) {
        self.tapAction(self.media);
    }
}

@end

@interface PreviewUser () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak) User *user;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *media;
@property (nonatomic, weak) Media *presentedMedia;
@property (nonatomic) BOOL toggleView;
@property (nonatomic, strong) MediaView *mediaView;
@property (nonatomic, strong) UIView *container;
@end

@implementation PreviewUser

+ (void)showUser:(User *)user
{
    [user.media fetched:^{
        PreviewUser *preview = [[PreviewUser alloc] initWithUser:user];
        
        /*
        preview.alpha = 0;
        [mainWindow addSubview:preview];
        [UIView animateWithDuration:0.3 animations:^{
            preview.alpha = 1.0f;
        }];
        */
        
        CGRect finalFrame = mainWindow.bounds;
        
        preview.container = [[UIView alloc] initWithFrame:mainWindow.bounds];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:mainWindow.bounds];
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.alpha = 0.0f;
        backgroundView.tag = 1199;
        
        preview.container.backgroundColor = [UIColor darkGrayColor];
        preview.container.backgroundColor = kAppColor;
        UIView *screenshot = [[UIApplication sharedApplication].keyWindow snapshotViewAfterScreenUpdates:NO];
        screenshot.radius = 4.0f;
        screenshot.clipsToBounds = YES;
        screenshot.tag = 1299;
        
        [preview.container addSubview:screenshot];
        [preview.container addSubview:backgroundView];

        preview.frame = CGRectMake(0, CGRectGetHeight(preview.frame), CGRectGetWidth(preview.frame), CGRectGetHeight(preview.frame));
        
        [preview.container addSubview:preview];
        [mainWindow addSubview:preview.container];
        
        [UIView animateWithDuration:0.5f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             backgroundView.alpha = 0.6;
                             [screenshot setTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(0.96f, 0.96f), 0 ,0.0f)];
                         } completion:nil];
        
        [UIView animateWithDuration:0.3f
                              delay:0.2f
             usingSpringWithDamping:0.88f
              initialSpringVelocity:1.2f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             preview.frame = finalFrame;
                         }
                         completion:^(BOOL finished) {
                         }];
    }];
}

- (void) tapped:(id)sender
{
    const CGFloat duration = 0.3f;

    /*
    [UIView animateWithDuration:duration animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self killThisView];
    }];
    */
    UIView *backgroundView = [self.container viewWithTag:1199];
    UIView *screenshot = [self.container viewWithTag:1299];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         screenshot.transform = CGAffineTransformIdentity;
                         self.frame = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
                         backgroundView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         self.container.alpha = 0;
                         [self killThisView];
                     }];

    /*
*/
}


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
    
    self.mediaView = [MediaView new];
    self.mediaView.collectionViewHeightOffset = 80.0f;
    [self.preview addSubview:self.mediaView];
}

- (void)setupMedia
{
    self.media = [NSMutableArray array];
    if (self.user.media) {
        @synchronized (self.media) {
            [self.media insertObject:self.user.media atIndex:0];
            [self.collectionView reloadData];
        }
        [self selectFirstMedia];
    }
    
    [self.user.photos enumerateObjectsUsingBlock:^(Media * _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
        [photo fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            @synchronized (self.media) {
                [self.media addObject:photo];
                [self.collectionView reloadData];
            }
        }];
    }];
}

- (void)selectFirstMedia
{
    __LF
    
    Media *firstMedia = self.media.firstObject;
    
    if (firstMedia) {
        [self.mediaView setMedia:firstMedia];
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
    __LF
    
    self.frame = mainWindow.bounds;
    self.preview.frame = self.bounds;
    self.mediaView.frame = self.bounds;
    [self.mediaView setNeedsLayout];
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
        if (![media isEqual:self.presentedMedia]) {
            [self.mediaView setMedia:media];
            self.presentedMedia = media;
        }
    };
    return cell;
}

- (void) killThisView
{
    __LF
    self.user = nil;
    [self.mediaView removeFromSuperview];
    [self.preview removeFromSuperview];
    [self.collectionView removeFromSuperview];
    [self.media removeAllObjects];
    self.media = nil;
    self.presentedMedia = nil;
    [self removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)dealloc
{
    NSLog(@"Dealloc %s %@", __func__, self.user.nickname);
}

@end

@interface PreviewMedia()
@property (strong, nonatomic) MediaView *mediaView;
@property (strong, nonatomic) UIView *container;
@end

@implementation PreviewMedia

+ (void)showMedia:(Media *)media
{
    [media fetched:^{
        PreviewMedia *preview = [[PreviewMedia alloc] initWithMedia:media];
        
        /*
        preview.alpha = 0;
        [mainWindow addSubview:preview];
        [UIView animateWithDuration:0.3 animations:^{
            preview.alpha = 1.0f;
        }];
        */
        
        CGRect finalFrame = mainWindow.bounds;
        
        preview.container = [[UIView alloc] initWithFrame:mainWindow.bounds];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:mainWindow.bounds];
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.alpha = 0.0f;
        backgroundView.tag = 1199;
        
        preview.container.backgroundColor = [UIColor darkGrayColor];
        preview.container.backgroundColor = kAppColor;
        UIView *screenshot = [[UIApplication sharedApplication].keyWindow snapshotViewAfterScreenUpdates:NO];
        screenshot.radius = 4.0f;
        screenshot.clipsToBounds = YES;
        screenshot.tag = 1299;
        
        [preview.container addSubview:screenshot];
        [preview.container addSubview:backgroundView];
        
        preview.frame = CGRectMake(0, CGRectGetHeight(preview.frame), CGRectGetWidth(preview.frame), CGRectGetHeight(preview.frame));
        
        [preview.container addSubview:preview];
        [mainWindow addSubview:preview.container];
        
        [UIView animateWithDuration:0.5f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             backgroundView.alpha = 0.6;
                             [screenshot setTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(0.96f, 0.96f), 0 ,0.0f)];
                         } completion:nil];
        
        [UIView animateWithDuration:0.3f
                              delay:0.2f
             usingSpringWithDamping:0.88f
              initialSpringVelocity:1.2f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             preview.frame = finalFrame;
                         }
                         completion:^(BOOL finished) {
                         }];
    }];
}

- (instancetype)initWithMedia:(Media *)media
{
    CGRect frame = mainWindow.bounds;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.mediaView = [MediaView new];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:   @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
        [self addSubview:self.mediaView];
        [self.mediaView setMedia:media];
    }
    return self;
}

- (void) tapped:(id)sender
{
    [self kill];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    __LF
    
    self.frame = mainWindow.bounds;
    self.mediaView.frame = self.bounds;
    [self.mediaView setNeedsLayout];
}

- (void) kill
{
    const CGFloat duration = 0.3f;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    /*
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.mediaView removeFromSuperview];
        [self removeFromSuperview];
    }];
 */
    
    UIView *backgroundView = [self.container viewWithTag:1199];
    UIView *screenshot = [self.container viewWithTag:1299];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         screenshot.transform = CGAffineTransformIdentity;
                         self.frame = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
                         backgroundView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         self.container.alpha = 0;
                         [self.mediaView removeFromSuperview];
                         [self removeFromSuperview];
                     }];

}

@end
