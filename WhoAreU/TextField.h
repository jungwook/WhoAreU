//
//  TextField.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 16..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSaveString @"save"

typedef BOOL(^TextFieldValidation)(NSString *text);

@interface TextField : UITextField
@property (nonatomic, strong) IBInspectable UIFont *placeholderFont;
@property (nonatomic, strong) IBInspectable UIColor *colorValid, *colorInvalid, *colorDefault, *pickerTextColor, *pickerBackgroundColor, *undoColor, *saveColor;
@property (nonatomic, copy) TextFieldValidation shouldValidateAction;
@property (nonatomic, copy) TextFieldValidation validatedAction;
@property (nonatomic, copy) StringBlock saveAction;
@property (nonatomic) IBInspectable BOOL optional, readonly, floating;
- (void)setSelection:(NSArray *)items
             default:(NSString*)item
          saveAction:(StringBlock)saveAction;
- (void)refreshWithItem:(NSString*)item;
@end


@interface EmailTextField : TextField

@end

