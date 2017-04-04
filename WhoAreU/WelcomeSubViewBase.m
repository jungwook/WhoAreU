//
//  WelcomeSubViewBase.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "WelcomeSubViewBase.h"

@implementation WelcomeSubViewBase

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    __LF
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    
}

- (void)viewOnTop
{
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([view isKindOfClass:[UITextField class]]) {
            [view becomeFirstResponder];
        }
    }];
}


@end
