//
//  InputBar.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^KeyboardEventBlock)(CGFloat duration,UIViewAnimationOptions options, CGRect keyboardFrame);
typedef void(^FloatEventBlock)(CGFloat value);

@interface InputBar : UIView
@property (copy, nonatomic) KeyboardEventBlock keyboardEvent;
@property (copy, nonatomic) FloatEventBlock heightChangeEvent;
@property CGFloat height;
@end
