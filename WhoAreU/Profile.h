//
//  Profile.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ProfileSectionProfile = 0,
    ProfileSectionComments,
} ProfileSections;

typedef enum : NSUInteger {
    RowTypeProfile = 0,
    RowTypeFollowers,
    RowTypeFollowing,
    RowTypeMap,
} ProfileRowType;

#define kSegueIdentifierChat @"Chat"
#define kProfileCell @"ProfileCell"
#define kUserMapCell @"UserMapCell"
#define kFollowCell @"FollowCell"
#define kCommentCell @"CommentCell"
#define kAddCommentCell @"AddCommentCell"

@interface Profile : UITableViewController
@property (nonatomic, strong) User *user;
@end
