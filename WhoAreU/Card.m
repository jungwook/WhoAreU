//
//  Card.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Card.h"
#import "CompassView.h"
#import "IndentedLabel.h"
#import "MaterialDesignSymbol.h"
#import "MediaPlayer.h"
#import "TabBar.h"

@interface Card()
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIImageView *imageArea;
@property (weak, nonatomic) IBOutlet UIView *presentationArea;
@property (weak, nonatomic) IBOutlet UILabel *presentationLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet CompassView *compass;
@property (weak, nonatomic) IBOutlet IndentedLabel *channelLabel;
@property (weak, nonatomic) IBOutlet IndentedLabel *genderLabel;
@property (weak, nonatomic) IBOutlet IndentedLabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *sourceButton;
//@property (weak, nonatomic) IBOutlet TabBar *bar;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (nonatomic, readonly) CGFloat width, height;
@property (strong, nonatomic) MediaPlayer *player;
@property (nonatomic, readonly) BOOL isVideo;
@end

@implementation Card

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

-(void)dealloc
{
    __LF
}

- (void)setupVariables
{
    __LF
}

- (void)awakeFromNib
{
    [super awakeFromNib];

//    self.bar.items = @[
//                       @{ fTitle : @"Profile", fBadge : @(0) },
//                       @{ fTitle : @"Location", fBadge : @(0) },
//                       @{ fTitle : @"Gallery", fBadge : @(0) },
//                       ];
    self.player = [MediaPlayer new];
    self.maskView.radius = kMaskViewRadius;
    self.maskView.clipsToBounds = YES;
    
    self.genderLabel.textInsets = UIEdgeInsetsZero;
    self.genderLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.likeButton setImage:[[UIImage imageNamed:@"heart"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self.imageArea addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedImage:)]];
    
    self.imageArea.tintColor = [UIColor redColor];
}

- (UIFont *)titleFont
{
    return self.titleLabel.font;
}

- (UIFont *)subTitleFont
{
    return self.subTitleLabel.font;
}

- (UIFont *)presentationFont
{
    return self.presentationLabel.font;
}

- (UIFont *)statusFont
{
    return self.statusLabel.font;
}

- (CGFloat)width
{
    return CGRectGetWidth(self.bounds);
}

- (CGFloat)height
{
    return CGRectGetHeight(self.bounds);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
//    self.clipsToBounds = NO;
//    self.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.layer.shadowOffset = CGSizeZero;
//    self.layer.shadowRadius = 0.5f;
//    self.layer.shadowOpacity = 0.5f;
//    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.maskView.radius].CGPath;
}

- (void)playVideoIfVideo
{
    if (self.isVideo) {
        [self.player setMedia:self.isVideo ? self.user.media.media : nil attachOnView:self.imageArea];
    }
    else {
        [self.player stopCurrentPlayback];
    }
}

- (BOOL)isVideo
{
    return (self.user && self.user.media.type == kMediaTypeVideo);
}

- (void)tappedImage:(id)sender {
    __LF
}

- (void)setUser:(User *)user
{
    _user = user;
    
    [S3File getImageFromFile:user.media.type == kMediaTypePhoto ? user.media.media : user.media.thumbnail imageBlock:^(UIImage *image) {
        self.imageArea.image = image;
        self.sourceButton.hidden = (image == nil);
    }];
    
    self.titleLabel.text = user.nickname;
    self.subTitleLabel.text = user.age.uppercaseString;
    self.presentationLabel.text = user.introduction;
    self.channelLabel.text = user.channel;
    self.genderLabel.text = user.genderCode;
    
    self.compass.heading = [[User me].where headingToLocation:user.where];
    self.distanceLabel.text = [[User me].where distanceStringToLocation:user.where];
    self.statusLabel.text = [NSString stringWithFormat:@"member since %@", user.createdAt.timeAgo].uppercaseString;
    
//    [self gotoSelectedIndex];
//    self.bar.selectAction = ^(NSUInteger index) {
//        self.user[fSelectedTabBarIndex] = @(index);
//    };
//    
//    [self.bar updateItem:@{ fTitle : @"Gallery", fBadge : @(user.photos.count) } atIndex:eSectionGallery];

    UIImage *camera = TemplateImage(kCardCameraIcon);
    UIImage *file = TemplateImage(kCardPhotoIcon);
    
    [self.sourceButton setImage:user.media.source == kSourceTaken ? camera : file forState:UIControlStateNormal];
    self.sourceButton.tintColor = [UIColor whiteColor];
    
    NSLog(@">>>>> %@ %ld", sections.sectionGallery, sizeof(TabBarSections)/sizeof(id));
    
    [self setPrimaryColorsAs:[UIColor blackColor] alt:[UIColor whiteColor] gender:[self.user genderColor]];
}

//- (void)gotoSelectedIndex
//{
//    NSUInteger index = [self.user[fSelectedTabBarIndex] integerValue];
//    self.bar.index = index;    
//}

- (void)setPrimaryColorsAs:(UIColor*)color
                       alt:(UIColor*)altcolor
                    gender:(UIColor*)gender
{
    UIColor *faded = [color colorWithAlphaComponent:0.4];
    UIColor *genderfaded = [gender colorWithAlphaComponent:0.4];
    
    self.titleLabel.textColor = color;
    self.subTitleLabel.textColor = faded;
    
    self.distanceLabel.textColor = altcolor;
    self.distanceLabel.backgroundColor = gender;
    self.distanceLabel.borderColor = gender;
    self.distanceLabel.clipsToBounds = YES;
    self.distanceLabel.radius = 4.0f;

    self.genderLabel.backgroundColor = gender;
    self.genderLabel.textColor = altcolor;

    self.chatButton.tintColor = gender;

    self.channelLabel.borderColor = gender;
    self.channelLabel.backgroundColor = gender;
    self.channelLabel.textColor = altcolor;
    self.channelLabel.clipsToBounds = YES;
    
    self.presentationLabel.textColor = color;
    
//    self.bar.selectedColor = color;
//    self.bar.deselectedColor = faded;
//    self.bar.indicatorColor = color;
    
    self.statusLabel.textColor = faded;
    self.compass.compassColor = gender;
    self.compass.pointerColor = [UIColor whiteColor];
    self.sourceButton.tintColor = altcolor;
    self.likeButton.tintColor = [[User me] likes:self.user] ? gender : genderfaded;
}

TabBarSections sections = {
    .sectionProfile = @"sectionProfile",
    .sectionLocation = @"sectionLocation",
    .sectionGallery = @"sectionGallery",
};

@end
