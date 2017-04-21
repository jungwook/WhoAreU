//
//  ChatView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 16..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ChatView.h"

@implementation ChatView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RowCell"];
    }
    return self;
}

- (NSArray*) chats
{
    static BOOL dataSourceReady = NO;
    
    if (dataSourceReady) {
        return [self.chatDataSource chats];
    }
    
    if (self.chatDataSource && [self.chatDataSource respondsToSelector:@selector(chats)]) {
        dataSourceReady = YES;
        return [self.chatDataSource chats];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];
    
    return cell;
}

@end
