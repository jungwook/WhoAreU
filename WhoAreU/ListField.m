//
//  ListField.m
//  WithMe
//
//  Created by 한정욱 on 2016. 7. 21..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ListField.h"

@interface ListField()
@property (strong, nonatomic) UIPickerView *pickerView;
@end

@implementation ListField
@dynamic text;

+ (instancetype)listFieldWithItems:(NSArray*)items completion:(ListFieldBlock)handler
{
    ListField *listField = [ListField new];
    listField.pickerItems = items;
    listField.handler = handler;
    return listField;
}

+ (instancetype)listFieldForGenderWithCompletion:(ListFieldBlock)handler
{
    return [ListField listFieldWithItems:[User genders] completion:handler];
}

+ (instancetype)listFieldForIntroductionsWithCompletion:(ListFieldBlock)handler
{
    return [ListField listFieldWithItems:[User introductions] completion:handler];
}

+ (instancetype)listFieldForAgeGroupsWithCompletion:(ListFieldBlock)handler
{
    return [ListField listFieldWithItems:[User ageGroups] completion:handler];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initialize];
}

- (void) initialize
{
    self.pickerView = [UIPickerView new];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.inputView = self.pickerView;
    self.pickerView.showsSelectionIndicator = YES;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self selectItemWithText:text];
}

- (void)selectItemWithText:(NSString*)text
{
    NSUInteger row = [self.pickerItems indexOfObject:self.text];
    if (row != NSNotFound) {
        [self.pickerView selectRow:row inComponent:0 animated:NO];
    }
}

- (void)setPickerItems:(NSArray *)pickerItems withHandler:(ListFieldBlock)handler
{
    [self setPickerItems:pickerItems];
    self.handler = handler;
}

- (void)setPickerForGendersWithHandler:(ListFieldBlock)handler
{
    [self setPickerItems:[User genders] withHandler:handler];
}

- (void)setPickerForIntroductionsWithHandler:(ListFieldBlock)handler
{
    [self setPickerItems:[User introductions] withHandler:handler];
}

- (void)setPickerForAgeGroupsWithHandler:(ListFieldBlock)handler
{
    [self setPickerItems:[User ageGroups] withHandler:handler];
}

- (void)setPickerItems:(NSArray *)pickerItems
{
    _pickerItems = pickerItems;
    [self.pickerView reloadAllComponents];
    [self selectItemWithText:self.text];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerItems.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerItems[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self resignFirstResponder];
    self.text = self.pickerItems[row];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.handler) {
            self.handler(self.pickerItems[row]);
        }
    });
}


@end
