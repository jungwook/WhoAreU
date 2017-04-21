//
//  ChatView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 16..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChatViewDataSource;


@interface ChatView : UITableView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) id<ChatViewDataSource> chatDataSource;
@end

@protocol ChatViewDataSource <NSObject>
- (NSMutableArray*)chats;
@end
