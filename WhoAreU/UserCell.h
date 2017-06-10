//
//  UserCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndentedLabel.h"
#import "CompassView.h"
#import "PhotoView.h"

#define kIntroductionFont [UIFont systemFontOfSize:14]

@interface UserCell : UITableViewCell
@property (weak, nonatomic) User *user;
@property (weak, nonatomic) UIViewController* parent;
@property (copy, nonatomic) UserBlock chatAction;

- (void)tapped:(id)sender;
@end

@interface NoMoreCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@end
