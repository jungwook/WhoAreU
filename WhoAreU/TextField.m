//
//  TextField.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 16..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "TextField.h"
#import "MaterialDesignSymbol.h"

@interface KeyboardPicker : UIView <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, weak) TextField *parent;
@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) UIColor *textColor;
@end

@implementation KeyboardPicker

+ (instancetype) pickerWithItems:(NSArray*)items
                         default:(NSString*)item
                          parent:(TextField*)parent
{
    KeyboardPicker *picker = [[KeyboardPicker alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(mainWindow.bounds), 150)];
    picker.items = items;
    picker.parent = parent;
    [picker selectItem:item];
    return picker;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component
{
    id attr = @{
                NSForegroundColorAttributeName : self.textColor ? self.textColor : [UIColor whiteColor],
                };
    return [[NSAttributedString alloc] initWithString:self.items[row] attributes:attr];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.pickerView.frame = self.bounds;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pickerView = [UIPickerView new];
        self.pickerView.delegate = self;
        self.pickerView.dataSource = self;
        self.pickerView.showsSelectionIndicator = YES;
        [self addSubview:self.pickerView];
    }
    return self;
}

- (void)setItems:(NSArray*)items
{
    _items = items;
    [self.pickerView reloadAllComponents];
}

- (void)selectItem:(NSString*)item
{
    if (self.items) {
        NSUInteger row = [self.items indexOfObject:item];
        [self.pickerView selectRow:row != NSNotFound ? row : 0 inComponent:0 animated:NO];
    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.items.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.parent refreshWithItem:self.items[row]];
}

@end

@implementation EmailTextField

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self additionalSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self additionalSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self additionalSetup];
    }
    return self;
}

- (void)additionalSetup
{
    self.shouldValidateAction = ^BOOL(NSString *text) {
        return [text canBeEmail];
    };
    
    self.validatedAction = ^BOOL(NSString *text) {
        return [text isValidEmail];
    };
}

@end

@interface TextField() <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *save, *undo;
@property (nonatomic, strong) UIView *underline;
@property (nonatomic, strong) NSString* lastSaved;
@property (nonatomic, strong) KeyboardPicker *picker;
@property (nonatomic, readonly) CGFloat placeholderHeight,lineWidth, animationDuration, overlayWidth, overlayHeight, visibleOverlayWidth, saveWidth, saveHeight, undoWidth, undoHeight, inset, w, h;
@property (nonatomic, readonly) BOOL shouldValidate, validated, shouldShowSave, shouldShowUndo, filled, changed;
@property (nonatomic, readonly) NSString* placeholderTitle;
@property (nonatomic, readonly) UIColor *validatedPlaceholderColor;
@property (nonatomic, readonly) UIFont *buttonFont;
@end

@implementation TextField

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.lastSaved = self.text;
    self.placeholder = self.placeholder;
    [self valueChanged:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.delegate = self;
    
    self.placeholderFont = self.placeholderFont ? self.placeholderFont : [UIFont systemFontOfSize:8 weight:UIFontWeightMedium];
    
    self.colorDefault = [UIColor lightGrayColor];
    self.colorValid = [UIColor colorFromHexString:@"#00A641"];
    self.colorInvalid = [UIColor colorFromHexString:@"#FF8666"];
    self.saveColor = [[UIColor redColor] colorWithAlphaComponent:0.8];
    self.undoColor = [[UIColor grayColor] colorWithAlphaComponent:0.8];
    self.pickerTextColor = [UIColor blackColor];
    self.pickerBackgroundColor = [UIColor clearColor];
    
    self.placeholderLabel = [UILabel new];
    self.placeholderLabel.alpha = 0;

    self.underline = [UIView new];
    self.underline.alpha = 0;
    self.underline.radius = self.lineWidth / 2.0f;
    
    [self addSubview:self.underline];
    [self addSubview:self.placeholderLabel];

    self.rightView = [self overlayView];
    self.rightViewMode = UITextFieldViewModeAlways;
    
    [self addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventEditingChanged];
    if (self.placeholder == nil || [self.placeholder isEqualToString:kStringNull]) {
        self.placeholder = @"PLACEHOLDER";
    }
}

- (void)setReadonly:(BOOL)readonly
{
    self.userInteractionEnabled = !readonly;
}

- (CGFloat)placeholderHeight
{
    return self.placeholderFont.lineHeight;
}

- (CGFloat)lineWidth
{
    return 1.f;
}

- (CGFloat)animationDuration
{
    return 0.35f;
}

- (CGFloat)inset
{
    return 4.0f;
}

- (void)refreshWithItem:(NSString*)item
{
    [super setText:item];
    [self valueChanged:self];
}

- (void)setPickerTextColor:(UIColor *)pickerTextColor
{
    self.picker.textColor = pickerTextColor;
}

- (UIColor *)pickerTextColor
{
    return self.picker.textColor;
}

- (void)setSelection:(NSArray*)items
             default:(NSString*)item
          saveAction:(StringBlock)saveAction
{
    self.picker = [KeyboardPicker pickerWithItems:items default:item parent:self];
    self.inputView = self.picker;
    self.lastSaved = item;
    self.text = item;
    self.saveAction = saveAction;
}

- (void)setPickerBackgroundColor:(UIColor *)pickerBackgroundColor
{
    _pickerBackgroundColor = pickerBackgroundColor;
    self.picker.backgroundColor = pickerBackgroundColor;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectMake(0,
                      self.filled ? self.placeholderHeight : 0,
                      CGRectGetWidth(bounds) - self.visibleOverlayWidth,
                      CGRectGetHeight(bounds) - (self.filled ? self.placeholderHeight : 0));
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGFloat)w
{
    return CGRectGetWidth(self.bounds);
}

- (CGFloat)h
{
    return CGRectGetHeight(self.bounds);
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    return CGRectMake(self.w-self.overlayWidth-self.inset,
                      (self.h-self.overlayHeight)/2.0f,
                      self.overlayWidth,
                      self.overlayHeight);
}

- (UIView *)overlayView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    
    UIButton *save = [UIButton new];
    [save setTitle:kSaveString forState:UIControlStateNormal];
    save.radius = self.inset;
    save.titleLabel.font = self.buttonFont;
    save.titleLabel.textColor = [UIColor whiteColor];
    save.alpha = 0.0f;
    save.frame = CGRectMake(0, 0, self.saveWidth, self.saveHeight);
    [save addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchDown];
    [view addSubview:save];
    self.save = save;
    
    MaterialDesignSymbol *symbol = [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.undo24px fontSize:10];
    UIButton *undo = [UIButton new];
    [undo setAttributedTitle:[symbol symbolAttributedString] forState:UIControlStateNormal];
    undo.radius = self.saveHeight / 2.0f;
    undo.titleLabel.font = self.buttonFont;
    undo.titleLabel.textColor = [UIColor whiteColor];
    undo.frame = CGRectMake(self.saveWidth+self.inset, 0, self.saveHeight, self.saveHeight);
    [undo addTarget:self action:@selector(undo:) forControlEvents:UIControlEventTouchDown];
    [view addSubview:undo];
    self.undo = undo;

    view.frame = CGRectMake(0, 0, self.overlayWidth, self.overlayHeight);
    return view;
}

- (void)save:(id)sender
{
    self.lastSaved = self.text;
    if (self.saveAction) {
        self.saveAction(self.text);
    }
    
    CGRect frame = self.save.frame;
    frame.origin.x += self.overlayWidth+self.inset+self.inset;
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.save.frame = frame;
        self.save.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self resignFirstResponder];
    }];
}

- (void)undo:(id)sender
{
    if ([self.text isEqualToString:self.lastSaved]) {
        [super setText:nil];
        [self.picker selectItem:self.text];
        [self valueChanged:self];
    }
    else {
        self.text = self.lastSaved;
    }
}

- (void)setText:(NSString *)text
{
    self.lastSaved = text;
    
    [super setText:text];
    [self.picker selectItem:text];
    [self valueChanged:self];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    self.placeholderLabel.text = self.placeholder.uppercaseString;
}

- (void)valueChanged:(UITextField*)textField
{
    [self refreshPlaceholder];
    [self refreshPlaceholderTitle];
    [self refreshSaveButton];
    [self refreshUndoButton];
}

- (CGFloat)visibleOverlayWidth
{
    return (self.shouldShowSave ? self.saveWidth + self.inset : 0) + (self.shouldShowUndo ? self.undoWidth + self.inset : 0) + self.inset;
}

- (CGFloat)overlayWidth
{
    return self.saveWidth + self.inset + self.undoWidth+self.inset;
}

- (CGFloat)undoWidth
{
    return self.undoHeight;
}

- (CGFloat)undoHeight
{
    return [kSaveString heightWithFont:self.buttonFont];
}

- (CGFloat)overlayHeight
{
    return self.saveHeight;
}

- (UIFont *)buttonFont
{
    return [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
}

- (CGFloat) saveWidth
{
    return [kSaveString widthWithFont:self.buttonFont]+self.inset+self.inset;
}

- (CGFloat)saveHeight
{
    return [kSaveString heightWithFont:self.buttonFont]+self.inset;
}

- (BOOL)filled
{
    return (self.text.length > 0);
}

- (BOOL)changed
{
    return ![self.text isEqualToString:self.lastSaved];
}

- (BOOL)shouldShowSave
{
    BOOL ret = ((self.changed || (self.optional && !self.filled && self.changed)) && self.validated && self.editing);
    return ret;
}

- (BOOL)shouldShowUndo
{
    BOOL ret = self.editing && (self.changed || self.optional);
    return ret;
}

- (void)refreshPlaceholderTitle
{
    // Refreshing placeholderTitleLabel with validated title, validated color and validated underline color.
    // Do refresh when and only when current label differs to what it should be.
    
    if (![self.placeholderLabel.text isEqualToString:self.placeholderTitle]) {
        [UIView transitionWithView:self.placeholderLabel
                          duration:self.animationDuration
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.underline.backgroundColor = self.validatedPlaceholderColor;
                            self.placeholderLabel.text = self.placeholderTitle;
                            self.placeholderLabel.textColor = self.validatedPlaceholderColor;
                        } completion:nil];
    }
}

- (void)refreshSaveButton
{
    static BOOL showing = NO;
    
    if (self.shouldShowSave != showing) {
        showing = self.shouldShowSave;
        
        self.save.frame = self.shouldShowSave ? CGRectMake(self.overlayWidth, 0, self.saveWidth, self.saveHeight) : CGRectMake(0, 0, self.saveWidth, self.saveHeight);
        
        [UIView animateWithDuration:self.animationDuration animations:^{
            self.save.backgroundColor = self.saveColor ? self.saveColor : self.validatedPlaceholderColor;
            self.save.alpha = self.shouldShowSave;
            self.save.frame = !self.shouldShowSave ? CGRectMake(self.overlayWidth, 0, self.saveWidth, self.saveHeight) : CGRectMake(0, 0, self.saveWidth, self.saveHeight);
        }];
    }
    else {
        self.save.backgroundColor = self.saveColor ? self.saveColor : self.validatedPlaceholderColor;
        self.save.alpha = self.shouldShowSave;
        self.save.frame = !self.shouldShowSave ? CGRectMake(self.overlayWidth, 0, self.saveWidth, self.saveHeight) : CGRectMake(0, 0, self.saveWidth, self.saveHeight);
    }
}

- (void)refreshUndoButton
{
    static BOOL showing = NO;
    
    if (self.shouldShowUndo == showing)
        return;
    
    showing = self.shouldShowUndo;
    self.undo.frame = CGRectMake(self.saveWidth+self.inset, 0, self.saveHeight, self.saveHeight);
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.undo.alpha = self.shouldShowUndo;
        self.undo.backgroundColor = self.undoColor ? self.undoColor : [UIColor grayColor];
    }];
}

- (BOOL)shouldValidate
{
    // default is should not validate.
    
    return self.shouldValidateAction ? self.shouldValidateAction(self.text) : NO;
}

- (BOOL)validated
{
    // default is should be validated
    
    return self.validatedAction ? self.validatedAction(self.text) : YES;
}

- (NSString*) placeholderTitle
{
    NSString *placeholder = self.filled ? self.placeholder.uppercaseString : self.placeholder;
    return self.shouldValidate ? (self.validated ? placeholder : [placeholder stringByAppendingString:@" NOT VALID"]) : placeholder;
}

- (void)refreshPlaceholder
{
    static BOOL filled = NO;
    
    if (self.filled == filled)
        return;
    
    filled = self.filled;
    
    self.underline.frame = CGRectMake(0, self.h-self.lineWidth, self.w, self.lineWidth);
    self.underline.backgroundColor = self.validatedPlaceholderColor;
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.placeholderLabel.frame = self.filled ? CGRectMake(0, 0, self.w, self.placeholderHeight) : [super textRectForBounds:self.bounds];
        self.placeholderLabel.alpha = self.filled;
        self.placeholderLabel.font = self.filled ? self.placeholderFont : self.font;
        self.placeholderLabel.text = self.filled ? self.placeholder.uppercaseString : self.placeholder;
        self.placeholderLabel.textColor = self.filled ? self.validatedPlaceholderColor : [UIColor colorFromHexString:@"#C7C7CD"];
        self.underline.alpha = self.filled;
        self.underline.backgroundColor = self.validatedPlaceholderColor;
        self.underline.frame = CGRectMake(0, self.h-self.lineWidth, self.w, self.lineWidth);
    }];
}

- (UIColor*)validatedPlaceholderColor
{
    if (self.editing == NO)
        return self.colorDefault;
    
    return self.shouldValidate == NO ? self.colorDefault : (self.validated ? self.colorValid : self.colorInvalid);
}

- (void)dealloc
{
    __LF
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self valueChanged:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self valueChanged:self];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.shouldShowSave) {
        [self.save.layer addAnimation:self.shakeAnimation forKey:@"shake"];
        [self.save.layer addAnimation:self.redAnimation forKey:@"color"];
        return NO;
    }
    return YES;
}

- (CABasicAnimation*)redAnimation
{
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    animation.toValue = (id)[UIColor redColor].CGColor;
    animation.autoreverses = YES;
    animation.duration = 0.1;
    animation.removedOnCompletion = YES;
    animation.repeatCount = 1;
    
    return animation;
}

- (CAAnimation*)shakeAnimation
{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CGFloat wobbleAngle = 0.12f;
    
    NSValue* valLeft = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(wobbleAngle, 0.0f, 0.0f, 1.0f)];
    NSValue* valRight = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-wobbleAngle, 0.0f, 0.0f, 1.0f)];
    animation.values = [NSArray arrayWithObjects:valLeft, valRight, nil];
    
    animation.autoreverses = YES;
    animation.duration = 0.025;
    animation.repeatCount = 4;
    
    return animation;
}
@end
