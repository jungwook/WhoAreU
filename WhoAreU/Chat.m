//
//  Chat.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chat.h"
#import "ChatView.h"

@interface Chat ()
@property (strong, nonatomic) ChatView *chatView;
@property (strong, nonatomic) StringBlock sendTextAction;
@property (strong, nonatomic) MediaBlock sendMediaAction;

//@property CGFloat baseLine;
@end

@implementation Chat

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initializeInputPane];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:kNOTIFICATION_NEW_MESSAGE
                                               object:nil];
    
    [self.chatView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNOTIFICATION_NEW_MESSAGE object:nil];
}

- (void)newMessage:(id)sender
{
    [self.chatView reloadData];
}

- (NSArray *)chats
{
    __LF
    NSLog(@"Chats from user:%@[%@]", self.user.objectId, self.user.nickname);
    return [Engine messagesFromUser:self.user];
}

- (void)setUser:(User *)user
{
    _user = user;
 
    self.chatView.user = user;
    NSLog(@"SETTING USER TO:%@[%@]", self.user.objectId, self.user.nickname);
}

- (MediaBlock) sendMediaAction {
    return ^(Media *media) {
        NSLog(@"Sending Media:%@", media);
        [Engine send:media toUser:self.user];
        [self.chatView reloadData];
    };
}

- (StringBlock) sendTextAction {
    return ^(NSString *string) {
        NSLog(@"Sending Message:[%@]", string);
        [Engine send:string toUser:self.user];
        [self.chatView reloadData];
    };
}

- (void) initializeInputPane
{
    // add inputBar
    self.chatView = [[ChatView alloc] initWithFrame:self.view.bounds];

    [self.view addSubview:self.chatView];
    
    self.chatView.parent = self;
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
