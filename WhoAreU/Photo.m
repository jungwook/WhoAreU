//
//  Photo.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 11..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Photo.h"
@interface Photo()
@property (nonatomic) PhotoType type;
@end

@implementation Photo

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.circle = YES;
    self.type = kPhotoTypeUndefined;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}

- (void)tapped:(id)sender
{
    switch (self.type) {
        case kPhotoTypeMedia:
            [PreviewMedia showMedia:self.media];
            break;
            
        case kPhotoTypeUser:
            [PreviewUser showUser:self.user];
            break;
            
        default:
        case kPhotoTypeUndefined:
            
            break;
    }
}

- (void)setCircle:(BOOL)circle
{
    _circle = circle;
    self.clipsToBounds = circle;
}

- (void)layoutSubviews
{
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    if (self.circle) {
        self.radius = MIN(w, h) / 2.0f;
    }
    else {
        self.radius = 0;
    }
}

- (void)setMedia:(Media *)media
{
    _media = media;
    self.type = kPhotoTypeUndefined;
    if (self.media.dataAvailable) {
        if (self.thumbnail) {
            [self loadThumbnail:self.media.thumbnail type:kPhotoTypeMedia];
        }
        else {
            if (self.media.type == kMediaTypePhoto) {
                [self loadThumbnail:self.media.media type:kPhotoTypeMedia];
            }
            else {
                [self loadThumbnail:self.media.thumbnail type:kPhotoTypeMedia];
            }
        }
    }
    else {
        [self.media fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (self.thumbnail) {
                [self loadThumbnail:self.media.thumbnail type:kPhotoTypeMedia];
            }
            else {
                if (self.media.type == kMediaTypePhoto) {
                    [self loadThumbnail:self.media.media type:kPhotoTypeMedia];
                }
                else {
                    [self loadThumbnail:self.media.thumbnail type:kPhotoTypeMedia];
                }
            }
        }];
    }
}

- (void)setUser:(User *)user
{
    _user = user;
    self.type = kPhotoTypeUndefined;
    if (self.user.dataAvailable) {
        if (self.thumbnail) {
            [self loadThumbnail:self.user.thumbnail type:kPhotoTypeUser];
        }
        else {
            if (self.user.media.type == kMediaTypePhoto) {
                [self loadThumbnail:self.user.media.media type:kPhotoTypeUser];
            }
            else {
                [self loadThumbnail:self.user.media.thumbnail type:kPhotoTypeUser];
            }
        }
    }
    else {
        [self.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (self.thumbnail) {
                [self loadThumbnail:self.user.thumbnail type:kPhotoTypeUser];
            }
            else {
                if (self.user.media.type == kMediaTypePhoto) {
                    [self loadThumbnail:self.user.media.media type:kPhotoTypeUser];
                }
                else {
                    [self loadThumbnail:self.user.media.thumbnail type:kPhotoTypeUser];
                }
            }
        }];
    }
}

- (void)loadThumbnail:(NSString*)filename type:(PhotoType)type
{
    [self drawImage:[UIImage avatar]];
    if (filename && filename.length > 0) {
        [S3File getImageFromFile:filename imageBlock:^(UIImage *image) {
            if (image) {
                [self drawImage:image];
            }
            self.type = type;
        }];
    }
}

- (BOOL) thumbnail
{
    CGRect rect = self.bounds;
    CGFloat w = CGRectGetWidth(rect);
    
    return (w<kThumbnailWidth);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
