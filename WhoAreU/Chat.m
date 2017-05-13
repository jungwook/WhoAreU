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

- (void)viewDidAppear:(BOOL)animated
{
    __LF
}

- (void)setChannel:(Channel *)channel
{
    _channel = channel;
    self.chatView.channel = channel;
    self.navigationItem.title = channel.name;
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
