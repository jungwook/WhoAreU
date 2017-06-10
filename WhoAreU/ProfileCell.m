//
//  ProfileCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ProfileCell.h"
#import "MediaPage.h"
#import "PhotoView.h"
#import "IndentedLabel.h"
#import "PopupView.h"

@interface ProfileCell()
@property (weak, nonatomic) IBOutlet MediaPage *mediaPage;
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet IndentedLabel *channel;
@property (weak, nonatomic) IBOutlet IndentedLabel *gender;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@end

@implementation ProfileCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.introduction.font = [ProfileCell font];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    __io = self.introduction.frame.origin;
}

CGPoint __io;

+ (UIFont *)font
{
    return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
}

+ (CGPoint) introductionOffset
{
    return __io;
}

- (IBAction)doChat:(id)sender
{
    if (self.chatAction) {
        self.chatAction();
    }
}

- (void)setUser:(User *)user
{
    _user = user;
    
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (error) {
            LogError;
        }
        else {
            [self.photoView setUser:self.user];
            [self.mediaPage setUser:self.user];
            self.nickname.text = self.user.nickname;
            self.age.text = self.user.age;
            self.channel.text = self.user.channel;
            self.introduction.text = self.user.introduction;
            self.gender.text = self.user.genderTypeString;
            self.gender.backgroundColor = self.user.genderColor;
        }
    }];
}

@end
