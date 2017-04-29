//
//  Chat.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chat.h"
#import "ChatView.h"

@interface Chat () <ChatViewDataSource>
@property (strong, nonatomic) ChatView *chatView;
@property (strong, nonatomic) NSMutableArray *chats;
@property (strong, nonatomic) StringBlock sendTextAction;
@property (strong, nonatomic) MediaBlock sendMediaAction;

//@property CGFloat baseLine;
@end

@implementation Chat

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.chats = [NSMutableArray new];
    
    [self initializeInputPane];
}

- (MediaBlock) sendMediaAction {
    return ^(Media *media) {
        NSLog(@"Sending %@", media);
        Message* message = [Message media:media toUser:self.user];
        NSLog(@"MM:%@", message);
        [self.chats addObject:message.dictionary];
        [self.chatView reloadData];
    };
}

- (StringBlock) sendTextAction {
    return ^(NSString *string) {
        NSLog(@"[Sending %@]", string);
        Message* message = [Message message:string toUser:self.user];
        [self.chats addObject:message.dictionary];
        [self.chatView reloadData];
    };
}

- (void) initializeInputPane
{
    // add inputBar
    self.chatView = [[ChatView alloc] initWithFrame:self.view.bounds];

    [self.view addSubview:self.chatView];
    
    self.chatView.parent = self;
    self.chatView.dataSource = self;
    self.chatView.sendTextAction = self.sendTextAction;
    self.chatView.sendMediaAction = self.sendMediaAction;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tappedOutside:(id)sender {
    [self.view endEditing:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
