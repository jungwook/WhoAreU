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

@interface PhotoView()
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@end

@implementation PhotoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.frame = self.bounds;
    [self addSubview:self.activity];
}

- (void)setMedia:(Media *)media
{
    [self.activity startAnimating];
    _media = media;

    if (self.media) {
        [self.media fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            [S3File getDataFromFile:self.media.type == kMediaTypePhoto ? self.media.media : self.media.thumbnail dataBlock:^(NSData *data) {
                UIImage *photo = [UIImage imageWithData:data];
                self.image = photo;
            }];
        }];
    }
    else {
        self.image = [UIImage imageNamed:@"avatar"];
    }
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    self.layer.contents = (id) image.CGImage;
    self.layer.contentsGravity = kCAGravityResizeAspectFill;
    
    [self.activity stopAnimating];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    CGFloat l = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
//    self.layer.cornerRadius = l / 2.0f;
    self.layer.masksToBounds = YES;
    self.activity.frame = self.bounds;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([self hitTest:[touch locationInView:self] withEvent:nil] == self) {
        NSLog(@"Entering photo picker!");
    }
}

- (void)updateMediaOnParentViewController:(UIViewController *)parent
{
    void (^removeAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        self.me.media = nil;
        [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"User:%@", self.me);
        }];
        self.image = [UIImage imageNamed:@"avatar"];
    };
    void (^updateAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        [MediaPicker pickMediaOnViewController:parent withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                [self setMedia:media];
                self.me.media = media;
                [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    NSLog(@"User:%@", self.me);
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
    [parent presentViewController:alert animated:YES completion:nil];
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
