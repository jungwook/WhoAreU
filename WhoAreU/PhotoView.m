//
//  PhotoView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PhotoView.h"
#import "MediaPicker.h"
#import "S3File.h"
#import "Preview.h"

@interface PhotoView()
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@end

@implementation PhotoView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.frame = self.bounds;
    [self addSubview:self.activity];
    self.layer.masksToBounds = YES;
    self.image = [UIImage imageNamed:@"avatar"];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}
                               
- (void)tapped:(id)sender
{
    if (self.media && self.parent) {
        Preview *preview = [[Preview alloc] initWithMedia:self.media];
        preview.modalPresentationStyle = UIModalPresentationOverFullScreen;
        preview.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.parent presentViewController:preview animated:YES completion:nil];
    }
    else {
        NSLog(@"No image or no parent view controller set");
    }
}

- (void)setMedia:(Media *)media
{
    _media = media;

    [self.activity startAnimating];
    if (self.media) {
        [self.media fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            CGFloat size = MIN(CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));
            
            NSString *filename = self.media.type == kMediaTypeVideo ? self.media.thumbnail : (size < kThumbnailWidth ? self.media.thumbnail : self.media.media);
            
            [S3File getDataFromFile:filename dataBlock:^(NSData *data) {
                UIImage *photo = [UIImage imageWithData:data];
                self.image = photo;
                [self.activity stopAnimating];
            }];
        }];
    }
    else {
        self.image = [UIImage imageNamed:@"avatar"];
    }
    [self.activity stopAnimating];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    self.layer.contents = (id) image.CGImage;
    self.layer.contentsGravity = kCAGravityResizeAspectFill;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.activity.frame = self.bounds;
}

//- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    UITouch *touch = [touches anyObject];
//    if ([self hitTest:[touch locationInView:self] withEvent:nil] == self) {
//    }
//}

- (void)updateMedia
{
    void (^removeAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        self.me.media = nil;
        [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"User:%@", self.me);
        }];
        self.image = [UIImage imageNamed:@"avatar"];
        [self.activity stopAnimating];
    };
    void (^updateAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        [MediaPicker pickMediaOnViewController:self.parent withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                [self setMedia:media];
                self.me.media = media;
                [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    NSLog(@"User:%@", self.me);
                }];
            }
            [self.activity stopAnimating];
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
    [self.parent presentViewController:alert animated:YES completion:nil];
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
