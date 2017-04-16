//
//  Chat.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Chat.h"
#import "InputBar.h"

@interface Chat ()
@property (strong, nonatomic) InputBar *inputBar;
@property CGFloat baseLine;
@end

@implementation Chat

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initializeInputPane];
}

- (void) initializeInputPane
{
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat w = CGRectGetWidth(self.view.bounds);
    __weak typeof(self) weakSelf = self;
    
    self.inputBar = [InputBar new];
    self.inputBar.keyboardEvent = ^(CGFloat duration, UIViewAnimationOptions options, CGRect keyboardFrame) {
        
        CGFloat height = weakSelf.inputBar.height;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.baseLine = keyboardFrame.origin.y;
            [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
                [weakSelf.inputBar setFrame:CGRectMake(0, weakSelf.baseLine-height, w, height)];
            } completion:nil];
        });
    };
    self.inputBar.heightChangeEvent = ^(CGFloat height){
        weakSelf.inputBar.height = height;
        [weakSelf.inputBar setFrame:CGRectMake(0, weakSelf.baseLine - height, w, height)];
    };
    self.baseLine = h;
    self.inputBar.frame = CGRectMake(0, self.baseLine - 52, w, 52);
    [self.view addSubview:self.inputBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view.
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
