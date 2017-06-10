//
//  BlurView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "BlurView.h"

@interface BlurView()
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) UIView *imageView;
@end

@implementation BlurView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.effectView.frame = self.bounds;
}

- (void) initialize
{
    self.imageView = [UIView new];
    self.effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    [self addSubview:self.imageView];
    [self addSubview:self.effectView];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.imageView drawImage:image];
}

@end
