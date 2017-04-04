//
//  AddAgeSubView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "AddAgeSubView.h"
#import "ListField.h"

@interface AddAgeSubView()
@property (weak, nonatomic) IBOutlet ListField *age;
@end


@implementation AddAgeSubView

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
    self.backgroundColor = [UIColor clearColor];
    [self.age setPickerForAgeGroupsWithHandler:^(id item) {
        if (self.nextBlock) {
            self.nextBlock(item);
        }
    }];
}

- (IBAction)nextView:(id)sender {
    BOOL empty = [self.age.text isEqualToString:@""];
    if (!empty && self.nextBlock) {
        self.nextBlock(self.age.text);
    }
}

- (IBAction)previousView:(id)sender {
    if (self.prevBlock) {
        self.prevBlock();
    }
}

@end
