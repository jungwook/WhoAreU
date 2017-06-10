//
//  Chat.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chat.h"
#import "ChatView.h"
#import "MessageCenter.h"

@interface Chat ()
@property (strong, nonatomic) ChatView *chatView;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) id channelId;
@end

@implementation Chat

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void) setup
{
    self.chatView = [[ChatView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:self.chatView];
    self.chatView.parent = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    __LF
    [self.chatView reloadDataAnimated:NO];
}

- (void)viewDidLoad
{
    __LF
}

- (void)viewDidAppear:(BOOL)animated
{
    __LF
}

- (id)channelId
{
    return self.dictionary[fObjectId];
}

- (void)setDictionary:(id)dictionary
{
    __LF
    
    _dictionary = dictionary;
    
    self.chatView.channel = self.dictionary;
    NSString *title = [MessageCenter channelNameFromChannel:dictionary];
    NSLog(@"Chatting:%@\n%@", title, self.dictionary);
    self.navigationItem.title = title;
    [MessageCenter processFetchMessagesForChannelId:self.channelId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)tappedOutside:(id)sender {
    [self.view endEditing:YES];
}

@end
