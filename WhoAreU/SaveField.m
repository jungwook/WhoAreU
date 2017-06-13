//
//  SaveField.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "SaveField.h"

@interface SaveField() <UITextFieldDelegate>

@property (strong, nonatomic) UIButton *save;
@property (strong, nonatomic) UITextField *textField;
@property (strong, nonatomic) NSString *lastSaved;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) NSArray *pickerItems;
@property (copy, nonatomic) SaveFieldBlock handler;
@end

@implementation SaveField

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
        
        self.lastSaved = @"";
        self.textField = [UITextField new];
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.textField.textColor = kAppColor;
        
        self.save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.save setTitle:@"SAVE" forState:UIControlStateNormal];
        self.save.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        self.save.backgroundColor = [UIColor femaleColor];
        self.save.tintColor = [UIColor whiteColor];
        self.save.alpha = 0.0f;
        self.save.radius = 4.0f;
        self.save.clipsToBounds = YES;
        
        [self.save addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchDown];
        [self.textField addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [self addSubview:self.textField];
        [self addSubview:self.save];
    }
    return self;
}

- (void)save:(id)sender
{
    self.lastSaved = self.textField.text;
    [self.textField resignFirstResponder];
    if (self.saveAction) {
        self.saveAction(self.textField.text);
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.save.alpha = 0;
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect rect = self.bounds;
    const CGFloat height = 22, width = 50, offset = 8, w = CGRectGetWidth(rect), h = CGRectGetHeight(rect);
    self.save.frame = CGRectMake(w-width-offset, (h-height)/2.0f, width, height);
    self.textField.frame = CGRectMake(0, 0, w-width-offset, h);
}

- (void)valueChanged:(UITextField*)textField
{
    BOOL alpha = !([textField.text isEqualToString:self.lastSaved]);
    
    if (alpha != self.save.alpha) {
        [UIView animateWithDuration:0.25 animations:^{
            self.save.alpha = alpha;
        }];
    }
}

- (void)setFont:(UIFont *)font
{
    self.textField.font = font;
}

- (UIFont *)font
{
    return self.textField.font;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.textField.placeholder = placeholder;
}

- (NSString *)placeholder
{
    return self.textField.placeholder;
}

- (void)setText:(NSString *)text
{
    self.textField.text = text;
    [self selectItemWithText:text];
}

-(NSString *)text
{
    return self.textField.text;
}

- (void)setTextColor:(UIColor *)textColor
{
    self.textField.textColor = textColor;
}

- (UIColor *)textColor
{
    return self.textField.textColor;
}

- (void) initialize
{
    self.pickerView = [UIPickerView new];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.showsSelectionIndicator = YES;
}

- (void)selectItemWithText:(NSString*)text
{
    NSUInteger row = [self.pickerItems indexOfObject:self.text];
    if (row != NSNotFound) {
        [self.pickerView selectRow:row inComponent:0 animated:NO];
    }
}

- (void)setPickerItems:(NSArray *)pickerItems picked:(SaveFieldBlock)handler
{
    self.textField.inputView = self.pickerView;
    [self setPickerItems:pickerItems];
    self.handler = handler;
}

- (void)setPickerItems:(NSArray *)pickerItems picked:(SaveFieldBlock)handler saved:(StringBlock)saveAction
{
    [self setPickerItems:pickerItems picked:handler];
    self.saveAction = saveAction;
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

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.text = self.pickerItems[row];
    [self valueChanged:self.textField];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.handler) {
            self.handler(row, self.pickerItems[row]);
        }
    });
}

@end
