//
//  AddNicknameSubView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AddNicknameSubView.h"

@interface AddNicknameSubView()
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UIButton *nextBut;

@end

@implementation AddNicknameSubView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSLog(@"initWithCoder");
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSLog(@"awakeFrom");
    
    self.nextBut.enabled = false;
    [self.nickname becomeFirstResponder];
}

- (IBAction)nextView:(id)sender {
}

@end
