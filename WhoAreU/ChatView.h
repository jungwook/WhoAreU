//
//  ChatView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LEFTBUTSIZE 45
#define INSET 8
#define SENDBUTSIZE 50
#define LINEHEIGHT 17
#define TEXTVIEWHEIGHT 48

#define CHATMAXWIDTH 200
#define MEDIASIZE 160

@protocol ChatViewDataSource;

@interface ChatView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) UIViewController *parent;
@property (copy, nonatomic) StringBlock sendTextAction;
@property (copy, nonatomic) MediaBlock sendMediaAction;
@property (nonatomic, weak) id<ChatViewDataSource> dataSource;
-(void) reloadData;
@end

@protocol ChatViewDataSource <NSObject>
- (NSMutableArray*)chats;
@end
