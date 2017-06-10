//
//  UserMapCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserMapCell : UITableViewCell
@property (strong, nonatomic) User *user;
@property (copy, nonatomic) UserViewRectBlock photoAction;
@end
