//
//  AddIntroductionsSubView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AddIntroductionsSubView.h"
#import "ListField.h"

@interface AddIntroductionsSubView()
@property (weak, nonatomic) IBOutlet ListField *introduction;
@end

@implementation AddIntroductionsSubView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.introduction setPickerForIntroductionsWithHandler:^(id item) {
        if (self.nextBlock) {
            self.nextBlock(item);
        }
    }];
}
@end
