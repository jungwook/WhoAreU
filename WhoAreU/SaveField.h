//
//  SaveField.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SaveFieldBlock)(NSUInteger index, id item);

@interface SaveField : UIView <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, copy) StringBlock saveAction;
@property (nonatomic, strong) IBInspectable UIFont*font;
@property (nonatomic, strong) IBInspectable NSString *placeholder, *text;
@property (nonatomic, strong) IBInspectable UIColor *textColor;

- (void)setPickerItems:(NSArray *)pickerItems picked:(SaveFieldBlock)handler;

- (void)setPickerItems:(NSArray *)pickerItems picked:(SaveFieldBlock)handler saved:(StringBlock)saveAction;

@end
