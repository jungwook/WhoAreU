//
//  FollowCell.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    FollowCellTypeFollows = 0,
    FollowCellTypeFollowing,
} FollowCellType;

@interface FollowCell : UITableViewCell
@property (copy, nonatomic) UserViewRectBlock photoAction;
@property (strong, nonatomic) NSArray<User*> *users;
- (void) setNickname:(id)nickname type:(FollowCellType)type;

@end
