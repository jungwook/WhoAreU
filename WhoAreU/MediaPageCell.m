//
//  MediaPageCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MediaPageCell.h"
#import "Photo.h"

@interface MediaPageCell()
@property (weak, nonatomic) IBOutlet Photo *photo;
@property (strong, nonatomic) CAGradientLayer *gradient;
@end

@implementation MediaPageCell

- (CGColorRef) blackWithAlpha:(CGFloat)alpha
{
    return [UIColor colorWithWhite:0 alpha:alpha].CGColor;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.photo.circle = NO;
    self.gradient = [CAGradientLayer new];
    self.gradient.colors = @[
                             (id)[self blackWithAlpha:0.0],
                             (id)[self blackWithAlpha:0.0],
                             (id)[self blackWithAlpha:0.1],
                             (id)[self blackWithAlpha:0.2],
                             (id)[self blackWithAlpha:0.3],
                             (id)[self blackWithAlpha:0.4],
                                  ];
    
    self.gradient.locations = @[
                                @(0.00),
                                @(0.40),
                                @(0.60),
                                @(0.80),
                                @(0.90),
                                @(0.95),
                                @(1.00),
                                ];

    [self.layer addSublayer:self.gradient];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.gradient.frame = self.bounds;
}

-(void)setMedia:(Media *)media
{
    _media = media;
    [self.photo setMedia:media];
}

@end
