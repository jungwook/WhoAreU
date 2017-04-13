//
//  PhotoView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PhotoView.h"
#import "S3File.h"

@interface PhotoView()
@property (strong, nonatomic) Media* media;
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
    
    self.clipsToBounds = YES;
}

- (void)setMedia:(Media *)media
{
    _media = media;
    
    [S3File getDataFromFile:self.media.type == kMediaTypePhoto ? self.media.media : self.media.thumbnail dataBlock:^(NSData *data) {
        UIImage *photo = [UIImage imageWithData:data];
        self.image = photo;
    }];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    self.layer.contents = (id) image.CGImage;
    self.layer.contentsGravity = kCAGravityResize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([self hitTest:[touch locationInView:self] withEvent:nil] == self) {
        NSLog(@"Entering photo picker!");
    }
}

@end
