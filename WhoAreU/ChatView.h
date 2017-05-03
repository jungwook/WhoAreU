//
//  ChatView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Balloon.h"

@interface ChatView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) UIViewController *parent;
@property (copy, nonatomic) StringBlock sendTextAction;
@property (copy, nonatomic) MediaBlock sendMediaAction;
@property (nonatomic, strong) User *user;
-(void) reloadData;
@end
