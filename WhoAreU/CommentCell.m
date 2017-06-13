//
//  CommentCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "CommentCell.h"
#import "IndentedLabel.h"

@interface CommentCell()
@property (weak, nonatomic) IBOutlet UIView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet IndentedLabel *channel;
@property (weak, nonatomic) IBOutlet IndentedLabel *gender;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *ago;
@end

@implementation CommentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self.photoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedPhoto:)]];
}

- (void) tappedPhoto:(UITapGestureRecognizer *)sender {
    CGRect rect = [self.contentView convertRect:self.photoView.frame toView:mainWindow];
    if (self.photoAction) {
        self.photoAction(self.comment.user,
                         self.photoView,
                         rect);
    }
}

- (void)setComment:(Comment *)comment
{
    _comment = comment;
    [S3File getImageFromFile:self.comment.thumbnail imageBlock:^(UIImage *image) {
        [self.photoView drawImage:image];
    }];
    self.nickname.text = self.comment.nickname;
    self.age.text = self.comment.age;
    self.distance.text = [[User where] distanceStringToLocation:self.comment.where];
    self.channel.text = self.comment.channel;
    self.gender.text = [User genderTypeStringFromGender:self.comment.gender];
    self.gender.backgroundColor = [User genderColorFromTypeString:self.gender.text];
    self.message.text = self.comment.comment;
    self.ago.text = [[self.comment.createdAt timeAgoSimple] stringByAppendingString:@" ago"];
}
@end
