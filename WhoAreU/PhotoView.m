//
//  PhotoView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PhotoView.h"
#import "MediaPicker.h"
#import "Preview.h"

#pragma mark UserView

@interface UserView()
@property (strong, nonatomic) PhotoView *photoView;
@property (strong, nonatomic) UILabel* gender;
@property (strong, nonatomic) UIView* ring;
@property (nonatomic) BOOL on;
@end

@implementation UserView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.photoView = [PhotoView new];
    self.photoView.backgroundColor = kAppColor;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    
    [self addSubview:self.photoView];
    
    self.ring = [UIView new];
    self.ring.borderWidth = 3.0f;
    self.ring.borderColor = kAppColor;
//    [self addSubview:self.ring];
    
    self.gender = [UILabel new];
    self.gender.textColor = [UIColor whiteColor];
    self.gender.font = [UIFont boldSystemFontOfSize:10];
    self.gender.textAlignment = NSTextAlignmentCenter;
    self.gender.clipsToBounds = YES;
    
    [self addSubview:self.gender];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(newMessage:)
                                             name:kNotificationNewChatMessage
                                           object:nil];
}

- (void)newMessage:(NSNotification*)notification
{
    id userInfo = notification.object;
    id payload = userInfo[fPayload];
    id senderId = payload[fSenderId];

    if ([senderId isEqualToString:self.user.objectId]) {
        [self setCount];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationNewChatMessage object:nil];
}

- (void)setUser:(User *)user
{
    _user = user;
    
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        self.photoView.user = user;
        self.photoView.backgroundColor = user.genderColor;
        
        self.gender.text = self.user.genderCode;
        self.gender.backgroundColor = self.user.genderColor;
        
        self.ring.borderColor = self.user.genderColor;
        
        [self setNeedsLayout];
        [self setCount];
    }];
}

- (void)setUserId:(id)userId withThumbnail:(id)thumbnail
{
    _user = [User objectWithoutDataWithObjectId:userId];
    [self.photoView setBackgroundColor:kAppColor];
    [self.photoView setUser:self.user thumbnail:thumbnail];
    [self setNeedsLayout];
    [self setCount];
}

- (void)setCount
{
//    [Engine countUnreadMessagesFromUser:self.user completion:^(NSUInteger count) {
//        if (count >0) {
//            self.badgeValue = [NSString stringWithFormat:@"%ld", count];
//        }
//        else {
//            self.badgeValue = nil;
//        }
//    }];
}

- (void)clear
{
    [self.photoView clear];
}

- (void)updateMediaOnViewController:(UIViewController *)viewController
                         completion:(ErrorBlock)handler
{
    [self.photoView updateMediaOnViewController:viewController
                                     completion:handler];
}

- (void)layoutSubviews
{
    const CGFloat g = 17;
    CGRect frame = self.bounds;
    CGFloat w = CGRectGetWidth(frame);
    CGFloat h = CGRectGetHeight(frame);
    CGFloat m = MIN(w, h);
    self.photoView.radius = m / 2.0f;
    self.photoView.frame = CGRectMake((w-m)/2.0f, h-m, m, m);
    self.gender.frame = CGRectMake(w-g, h-g, g, g);
    self.gender.radius = g/2.0f;
    self.ring.frame = self.photoView.frame;
    self.ring.radius = m/2.0f;
}

@end

#pragma mark PhotoView

@interface PhotoView()
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@property (strong, nonatomic) User *user;
@end

@implementation PhotoView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}
                               
- (void)setup
{
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.frame = self.bounds;
    [self addSubview:self.activity];
    
    self.clipsToBounds = YES;
    self.image = self.avatar;
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}

- (void)tapped:(id)sender
{
    PostNotification(kNotificationEndEditing, nil);
    if (self.user) {
        [PreviewUser showUser:self.user];
    }
    else {
        [PreviewMedia showMedia:self.media];
    }
}

- (void)setUser:(User *)user
{
    _user = user;
    
    [self.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        _media = user.media;
        if (self.media) {
            [self.activity startAnimating];
            [S3File getImageFromFile:user.thumbnail imageBlock:^(UIImage *image) {
                self.image = image;
                [self.activity stopAnimating];
            }];
        }
        else {
            self.media = nil;
            self.image = self.avatar;
        }
    }];
}

- (void)setUser:(User*)user thumbnail:(id)thumbnail
{
    _user = user;
    if (thumbnail) {
        [self.activity startAnimating];
        [S3File getImageFromFile:thumbnail imageBlock:^(UIImage *image) {
            self.image = image;
            [self.activity stopAnimating];
        }];
    }
    else {
        self.media = nil;
        self.user = nil;
        self.image = self.avatar;
    }
}

- (void)setUserId:(id)userId withThumbnail:(id)thumbnail
{
    _user = [User objectWithoutDataWithObjectId:userId];
    if (thumbnail) {
        [self.activity startAnimating];
        [S3File getImageFromFile:thumbnail imageBlock:^(UIImage *image) {
            self.image = image;
            [self.activity stopAnimating];
        }];
    }
    else {
        self.media = nil;
        self.user = nil;
        self.image = self.avatar;
    }
    [self.user fetchIfNeededInBackground];
}

- (void)setMedia:(Media *)media
{
    _media = media;

    self.image = self.avatar;

    if (self.media) {
        [self.activity startAnimating];
        [self.media fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (error) {
                LogError;
            }
            else {
                CGFloat size = MIN(CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));
                
                NSString *filename = self.media.type == kMediaTypeVideo ? self.media.thumbnail : (size < kThumbnailWidth ? self.media.thumbnail : self.media.media);
                [S3File getImageFromFile:filename imageBlock:^(UIImage *image) {
                    if (image) {
                        self.image = image;
                    }
                    else {
                        self.media = nil;
                    }
                    [self.activity stopAnimating];
                }];
            }
        }];
    }
}

- (void)setDictionary:(id)dictionary
{
    Media* media = [Media new];
    
    media.media = [dictionary objectForKey:fMedia];
    media.thumbnail = [dictionary objectForKey:fThumbnail];
    media.type = [[dictionary objectForKey:fType] integerValue];
    media.userId = [dictionary objectForKey:fUserId];
    media.comment = [dictionary objectForKey:fComment];
    media.source = [[dictionary objectForKey:fSource] integerValue];
    media.size = CGSizeFromString([dictionary objectForKey:fSize]);
    
    [self setMedia:media];
}

- (void)clear
{
    self.user = nil;
    self.media = nil;
    self.image = self.avatar;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    __drawImage(image, self);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.activity.frame = self.bounds;    
}

- (UIImage*) avatar
{
    static UIImage *avatar = nil;
    if (avatar) {
        return avatar;
    }
    else {
        avatar = [UIImage avatar];
    }
    
    return avatar;
}

- (void)updateMediaOnViewController:(UIViewController *)viewController
                         completion:(ErrorBlock)handler
{
    void (^removeAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        self.me.media = nil;
        [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                if (handler) {
                    handler(error);
                }
            }
            else {
                self.image = self.avatar;
                [self.activity stopAnimating];
                if (handler) {
                    handler(nil);
                }
            }
        }];
    };
    void (^updateAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        [MediaPicker pickMediaOnViewController:viewController withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                [self setMedia:media];
                self.me.media = media;
                [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (error) {
                        if (handler) {
                            handler(error);
                        }
                    }
                    else {
                        [self.activity stopAnimating];
                        if (handler) {
                            handler(nil);
                        }
                    }
                }];
            }
        }];
    };
    void (^cancelAction)(UIAlertAction * action) = ^(UIAlertAction* action) {
        [self.activity stopAnimating];
    };
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.me.media) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Remove Photo"
                                                  style:UIAlertActionStyleDestructive
                                                handler:removeAction]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Update Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:updateAction]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:cancelAction]];
    }
    else {
        [alert addAction:[UIAlertAction actionWithTitle:@"Add Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:updateAction]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:cancelAction]];
    }
    [self.activity startAnimating];
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (User*) me
{
    static User *me = nil;
    if (!me) {
        me = [User me];
    }
    return me;
}

@end
