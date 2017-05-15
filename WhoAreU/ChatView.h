//
//  ChatView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Balloon.h"

#define kChatViewHeaderHeight 40.0f
#define kChatViewHeaderFont [UIFont systemFontOfSize:12 weight:UIFontWeightBold]


@interface ChatView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) UIViewController *parent;
@property (nonatomic, strong) id channel;
- (void)reloadDataAnimated:(BOOL) animated;
@end
