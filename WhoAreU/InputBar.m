//
//  InputBar.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "InputBar.h"

#define LEFTBUTSIZE 45
#define INSET 8
#define SENDBUTSIZE 50

@interface InputBar() <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIButton *mediaBut, *sendBut;
@property (strong, nonatomic) UIView *border;
@end

@implementation InputBar

static inline UIViewAnimationOptions AnimationOptionsForCurve(UIViewAnimationCurve curve)
{
    return curve << 16;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addContents];
        self.height = 52;
    }
    return self;
}

- (void) addContents
{
    [self addBorder];
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self addMediaBut];
    [self addTextView];
    [self addSendBut];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doKeyBoardEvent:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doEndEditingEvent:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
    
}
- (void) dealloc
{
    // Unregister for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:nil];
}

- (void)doEndEditingEvent:(NSString *)string
{
}

- (void)doKeyBoardEvent:(NSNotification *)notification
{
    CGRect keyboardEndFrameWindow;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];
    
    double keyboardTransitionDuration;
    [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];
    
    UIViewAnimationCurve keyboardTransitionAnimationCurve;
    [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];
    
    if (self.keyboardEvent) {
        self.keyboardEvent(keyboardTransitionDuration, AnimationOptionsForCurve(keyboardTransitionAnimationCurve), keyboardEndFrameWindow);
    }
}

- (void) addBorder
{
    self.border = [UIView new];
    self.border.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0];
    [self addSubview:self.border];
}

- (void) addMediaBut
{
    self.mediaBut = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.mediaBut setTitle:@"+" forState:UIControlStateNormal];
    self.mediaBut.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightThin];
    [self.mediaBut addTarget:self action:@selector(mediaButPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.mediaBut];
}

- (void) addSendBut
{
    __LF
    self.sendBut = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendBut setTitle:@"SEND" forState:UIControlStateNormal];
    [self.sendBut addTarget:self action:@selector(sendButPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.sendBut];
}

- (void)sendButPressed:(id)sender
{
    NSLog(@"Send Pressed");
}

- (void)mediaButPressed:(id)sender
{
    NSLog(@"Media Pressed");
}

- (void) addTextView
{
    self.textView = [UITextView new];
    [self.textView setScrollEnabled:YES];
    
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.textView.backgroundColor = [UIColor whiteColor];
    
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.returnKeyType = UIReturnKeySend;
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.spellCheckingType = UITextSpellCheckingTypeNo;
    self.textView.enablesReturnKeyAutomatically = YES;
    self.textView.layer.cornerRadius = 5.0;
    self.textView.layer.borderWidth = 0.5;
    self.textView.textContainerInset = UIEdgeInsetsMake(8, 0, 0, 0);
    self.textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // view hierachy
    [self addSubview:self.textView];
}

CGRect rectForString(NSString *string, UIFont *font, CGFloat maxWidth)
{
    CGRect rect = CGRectIntegral([string boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{
                                                                NSFontAttributeName: font,
                                                                } context:nil]);
    return rect;
}

- (void)layoutSubviews
{
    const CGFloat offset = 4;
    
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    CGFloat h = CGRectGetHeight(self.frame);
    
    [self.border setFrame:CGRectMake(0, 0, size.width, 0.5)];
    [self.mediaBut setFrame:CGRectMake(offset,
                                       h-LEFTBUTSIZE,
                                       LEFTBUTSIZE-2*offset,
                                       LEFTBUTSIZE-2*offset)];
    [self.textView setFrame:CGRectMake(LEFTBUTSIZE,
                                       INSET,
                                       size.width-LEFTBUTSIZE-INSET-SENDBUTSIZE-INSET,
                                       size.height-2*INSET)];
    [self.sendBut setFrame:CGRectMake(
                                     size.width-SENDBUTSIZE-INSET,
                                      h-LEFTBUTSIZE, SENDBUTSIZE, LEFTBUTSIZE-2*offset)];
}

- (void)textViewDidChange:(UITextView *)textView{
    static CGRect previousRect;
    
    UITextPosition* pos = textView.endOfDocument;
    CGRect currentRect = [textView caretRectForPosition:pos];
    
    CGFloat nh = CGRectGetMinY(currentRect)+CGRectGetHeight(currentRect);
    CGFloat ph = CGRectGetMinY(previousRect)+CGRectGetHeight(previousRect);

    CGFloat tvh = MIN(MAX(nh+2*INSET, 52), 100);

    if (nh != ph){
        if (self.heightChangeEvent) {
            self.heightChangeEvent(tvh);
        }
    }
    previousRect = currentRect;
}


-(void)scrollTextViewToBottom:(UITextView *)textView {
    if(textView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    return YES;
}
@end
