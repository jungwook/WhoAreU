//
//  ProfileCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCell : UITableViewCell
@property (copy, nonatomic) VoidBlock chatAction;
@property (strong, nonatomic) User *user;

+ (UIFont*) font;
+ (CGPoint) introductionOffset;
@end
