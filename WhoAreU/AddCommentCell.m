//
//  AddCommentCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AddCommentCell.h"

@interface AddCommentCell() <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UITextView *commentView;
@property (weak, nonatomic) IBOutlet UILabel *placeholder;
@property (weak, nonatomic) IBOutlet UIButton *save;
@end

@implementation AddCommentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.commentView.delegate = self;
    [self clear:nil];

    [self.photoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedPhoto:)]];
    self.photoView.borderColor = [UIColor groupTableViewBackgroundColor];
    self.photoView.borderWidth = 1.f;
}

- (void) tappedPhoto:(UITapGestureRecognizer *)sender {
    CGRect rect = [self.contentView convertRect:self.photoView.frame toView:mainWindow];
    if (self.photoAction) {
        self.photoAction([User me],
                         self.photoView,
                         rect);
    }
}

- (void)setUser:(User *)user
{
    _user = user;
    [S3File getImageFromFile:[User me].thumbnail imageBlock:^(UIImage *image) {
        [self.photoView drawImage:image];
    }];
    self.nickname.text = [User me].nickname;
    self.age.text = [User me].age;
    self.distance.text = [[User where] distanceStringToLocation:self.user.where];
    
    _user = user;
}

- (void)showPlaceholder:(BOOL)show
{
    if (self.placeholder.alpha != show) {
        [UIView animateWithDuration:0.25 animations:^{
            self.placeholder.alpha = show;
        }];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    BOOL nothing = (textView.text.length == 0);
    [self showPlaceholder:nothing];
    self.save.enabled = !nothing;
    self.save.backgroundColor = [self.save.backgroundColor colorWithAlphaComponent:nothing ? 0.8 : 1.0];
}

- (IBAction)clear:(id)sender
{
    self.commentView.text = kStringNull;
    [self textViewDidChange:self.commentView];
}

- (IBAction)save:(id)sender
{
    NSString *comment = self.commentView.text;
    comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (comment.length == 0) {
        return;
    }
    
    Comment *message = [Comment new];
    
    message.user = [User me];
    message.thumbnail = [User me].thumbnail;
    message.nickname = [User me].nickname;
    message.age = [User me].age;
    message.channel = [User me].channel;
    message.gender = [User me].gender;
    message.onId = self.user.objectId;
    message.comment = comment;
    message.where = [User where];
    message.type = CommentTypeUser;
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            LogError;
        }
        else {
            if (self.saveAction) {
                self.saveAction(message);
            }
        }
    }];
    [self clear:nil];
}

- (IBAction)loadMore:(id)sender
{
    __LF
    
    if (self.loadMoreAction) {
        self.loadMoreAction();
    }
}

@end
