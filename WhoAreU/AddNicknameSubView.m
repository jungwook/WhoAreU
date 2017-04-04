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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL empty = [self.nickname.text isEqualToString:@""];
    if (!empty && self.nextBlock) {
        [self.nickname resignFirstResponder];
        self.nextBlock(self.nickname.text);
    }
    return empty;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.nickname.delegate = self;
}

- (IBAction)nextView:(id)sender {
    BOOL empty = [self.nickname.text isEqualToString:@""];
    if (!empty && self.nextBlock) {
        [self.nickname resignFirstResponder];
        self.nextBlock(self.nickname.text);
    }
}

@end
