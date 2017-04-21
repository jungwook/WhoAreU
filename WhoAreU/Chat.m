//
//  Chat.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chat.h"
#import "InputBar.h"
#import "ChatView.h"

@interface Chat () <ChatViewDataSource>
@property (strong, nonatomic) InputBar *inputBar;
@property (strong, nonatomic) ChatView *chatView;
@property (strong, nonatomic) NSMutableArray *chats;
//@property CGFloat baseLine;
@end

@implementation Chat

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.chats = [NSMutableArray new];
    [self initializeInputPane];
}

- (void) initializeInputPane
{
    CGFloat h = CGRectGetHeight(self.view.bounds);
    __weak typeof(self) weakSelf = self;

    // add chatView
    self.chatView = [ChatView new];
    self.chatView.chatDataSource = self;
    [self.view addSubview:self.chatView];

    // add inputBar
    self.inputBar = [InputBar new];
    self.inputBar.baseLine = h;

    [self.view addSubview:self.inputBar];
    
    self.inputBar.keyboardEvent = ^(CGFloat duration, UIViewAnimationOptions options, CGRect keyboardFrame) {
        CGFloat height = weakSelf.inputBar.height;
        weakSelf.inputBar.baseLine = CGRectGetMinY(keyboardFrame);
        CGFloat bl = weakSelf.inputBar.baseLine - height;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
                [weakSelf setFramesTo:bl barHeight:height];
            } completion:nil];
        });
    };
    self.inputBar.heightChangeEvent = ^(CGFloat height) {
        CGFloat bl = weakSelf.inputBar.baseLine - height;
        weakSelf.inputBar.height = height;
        [weakSelf setFramesTo:bl barHeight:height];
    };
    
    CGFloat height = self.inputBar.height;
    CGFloat bl = h - height;
    
    [self setFramesTo:bl barHeight:height];
}

- (void) setFramesTo:(CGFloat)baseLine barHeight:(CGFloat)height
{
    CGFloat w = CGRectGetWidth(self.view.bounds);

    self.inputBar.frame = CGRectMake(0,
                                     baseLine,
                                     w,
                                     height);
    self.chatView.frame = CGRectMake(0,
                                     0,
                                     w,
                                     baseLine);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tappedOutside:(id)sender {
    [self.view endEditing:YES];
}


- (CGFloat) appropriateLineHeightForMessage:(NSString*)message
{
    CGFloat width = [[[UIApplication sharedApplication] keyWindow] bounds].size.width * 0.7f;
    
    const CGFloat inset = 10;
    NSString *string = [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    UIFont *font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    CGRect frame = rectForString(string, font, width);
    return frame.size.height+inset*2.5;
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
