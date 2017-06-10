//
//  AddCommentCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddCommentCell : UITableViewCell
@property (copy, nonatomic) AnyBlock saveAction;
@property (copy, nonatomic) VoidBlock loadMoreAction;
@property (strong, nonatomic) User *user;
@property (copy, nonatomic) UserViewRectBlock photoAction;
@end
