//
//  UserCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "UserCell.h"
#import "Photo.h"

@interface UserCell ()
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet IndentedLabel *channel;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet IndentedLabel *gender;
@property (weak, nonatomic) IBOutlet Photo *photo;
@property (weak, nonatomic) IBOutlet IndentedLabel *ago;
@property (weak, nonatomic) IBOutlet CompassView *compass;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UIButton *like;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@property (weak, nonatomic) IBOutlet UIView *buttons;
@end

@implementation UserCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.introduction.font = kIntroductionFont;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
}

- (void) tappedPhoto:(id)sender
{
    [PreviewUser showUser:self.user];
}

-(void)setUser:(User *)usr
{
    _user = usr;
    
    CLLocationDirection heading = [[User where] headingToLocation:self.user.where];
    
    NSString *distanceString = [[User where] distanceStringToLocation:self.user.where];
    
    self.nickname.text = self.user.nickname;
    self.channel.text = self.user.channel;
    self.age.text = self.user.age;
    self.compass.heading = heading;
    self.distance.text = distanceString;
    self.gender.text = self.user.genderCode;
    self.gender.backgroundColor = self.user.genderColor;
    self.introduction.text = self.user.introduction;
    self.ago.text = self.user.updatedAt.timeAgo;
    [self setLikeStatus:[[User me] likes:self.user]];
    self.photo.user = self.user;
    [self setNeedsLayout];
}

- (void)setLikeStatus:(BOOL) likes
{
    if (likes) {
        [self.like setTitle:@"Unlike" forState:UIControlStateNormal];
        self.like.backgroundColor = [UIColor colorWithRed:240/255.f green:82/255.f blue:10/255.f alpha:1.0f];
        
    }
    else {
        [self.like setTitle:@"Like" forState:UIControlStateNormal];
        self.like.backgroundColor = [UIColor colorWithRed:0/255.f green:150/255.f blue:0/255.f alpha:1.0f];
    }
}

- (IBAction)doProfile:(id)sender {
    [self.parent performSegueWithIdentifier:@"Profile" sender:self.user];
}

- (IBAction)doChat:(id)sender {
    if (self.chatAction) {
        self.chatAction(self.user);
    }
}

- (IBAction)doLike:(id)sender {
    BOOL likes = [[User me] likes:self.user];
    if (likes) {
        [[User me] unlike:self.user];
    }
    else {
        [[User me] like:self.user];
    }
    [self setLikeStatus:!likes];
}

- (void)tapped:(id)sender
{
    [self.layer removeAllAnimations];
    [self.layer addAnimation:[self photoAnimations] forKey:nil];
}

- (CABasicAnimation*) photoAnimations
{
    const CGFloat sf = 1.02;
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
    
    scale.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(sf, sf, 1.0)];
    scale.duration = 0.1f;
    scale.autoreverses = YES;
    scale.repeatCount = 1;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scale.removedOnCompletion = YES;
    
    return scale;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self showView:self.buttons show:selected];
}

- (void) showView:(UIView*)view show:(BOOL)show
{
    CGRect frame = view.frame;
    CGFloat h = CGRectGetHeight(frame);
    
    if (view.alpha != show) {
        [UIView animateWithDuration:0.25 animations:^{
            view.transform = CGAffineTransformMakeTranslation(0, show ? 0 : h);
            view.alpha = show;
        }];
    }
}
@end


@implementation NoMoreCell
@end

