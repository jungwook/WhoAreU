//
//  AddNicknameSubView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddNicknameSubView : UIView <UITextFieldDelegate>
@property (nonatomic, copy) StringBlock nextBlock;
@property (nonatomic, copy) VoidBlock prevBlock;
@end
