//
//  ListField.h
//  WithMe
//
//  Created by 한정욱 on 2016. 7. 21..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ListFieldBlock)(id item);

@interface ListField : UITextField <UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) NSArray *pickerItems;
@property (copy, nonatomic) ListFieldBlock handler;
+ (instancetype)listFieldWithItems:(NSArray*)items completion:(ListFieldBlock)handler;
+ (instancetype)listFieldForGenderWithCompletion:(ListFieldBlock)handler;
+ (instancetype)listFieldForIntroductionsWithCompletion:(ListFieldBlock)handler;
+ (instancetype)listFieldForAgeGroupsWithCompletion:(ListFieldBlock)handler;

- (void)setPickerItems:(NSArray *)pickerItems withHandler:(ListFieldBlock)handler;
- (void)setPickerForGendersWithHandler:(ListFieldBlock)handler;
- (void)setPickerForAgeGroupsWithHandler:(ListFieldBlock)handler;
- (void)setPickerForIntroductionsWithHandler:(ListFieldBlock)handler;

@end
