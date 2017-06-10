//
//  FollowingUserCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "FollowingUserCell.h"
#import "PhotoView.h"

@interface FollowingUserCell()
@property (weak, nonatomic) IBOutlet UIView *userView;
@end

@implementation FollowingUserCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.userView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedUser:)]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.userView.radius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))/2.0f;
    self.userView.clipsToBounds = YES;
    self.userView.borderColor = [UIColor groupTableViewBackgroundColor];
    self.userView.borderWidth = 1.0f;
}

- (void)tappedUser:(UITapGestureRecognizer*)sender
{
    CGRect rect = [self.contentView convertRect:self.userView.frame
                                         toView:mainWindow];

    if (self.photoAction) {
        self.photoAction(self.user, self.userView, rect);
    }
}

-(void)setUser:(User *)user
{
    _user = user;
    
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
       [S3File getImageFromFile:self.user.thumbnail imageBlock:^(UIImage *image) {
           [self.userView drawImage:image];
       }];
    }];
}

@end
