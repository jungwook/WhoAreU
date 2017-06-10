//
//  CommentCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentCell : UITableViewCell
@property (copy, nonatomic) UserViewRectBlock photoAction;
@property (strong, nonatomic) Comment* comment;
@end
