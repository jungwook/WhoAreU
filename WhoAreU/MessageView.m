//
//  MessageView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 27..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MessageView.h"

@interface MessageView ()
@property (nonatomic, strong) UILabel *titleLable, *messageLabel;
@property (nonatomic, strong) NSMutableArray <UIButton*> *buttons;
@property (nonatomic, readonly) CGRect presentedFrame;
@property (nonatomic, readonly) CGFloat h, w, titleHeight, statusBarHeight, textWidth;
@property (nonatomic) CGFloat buttonHeight;
@property (nonatomic, strong) NSMutableDictionary *handlers;
@property (nonatomic, copy) VoidBlock cancel;
@end

@implementation MessageView

- (instancetype)init
{
    self = [super init];
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

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setAlignment:(NSTextAlignment)alignment
{
    self.titleLable.textAlignment = alignment;
    self.messageLabel.textAlignment = alignment;
}

- (void)setupVariables
{
    self.seconds = 3;
    self.vInset = 8.f;
    self.hInset = 8.f;
    self.fromDirection = MessageViewDirectionTop;
    self.toDirection = MessageViewDirectionTop;
    self.buttons = [NSMutableArray new];
    self.handlers = [NSMutableDictionary new];
    
    self.titleLable = [UILabel new];
    self.titleLable.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.titleLable.textColor = [UIColor whiteColor];
    
    self.messageLabel = [UILabel new];
    self.messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.messageLabel.textColor = [UIColor whiteColor];
    self.messageLabel.numberOfLines = 0;
    
    self.alignment = NSTextAlignmentCenter;
    
    [self addSubview:self.titleLable];
    [self addSubview:self.messageLabel];
    
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)]];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}

- (void)panning:(UIPanGestureRecognizer*)pan
{
    static BOOL started = NO;
    
    VoidBlock completion = ^(){
        started = NO;
        if (self.cancel) {
            self.cancel();
        }
    };

    CGPoint velocity = [pan velocityInView:self];
    CGFloat left = (velocity.x < 0) ? -velocity.x : 0;
    CGFloat right = (velocity.x > 0) ? velocity.x : 0;
    CGFloat top = (velocity.y < 0) ? -velocity.y : 0;
    CGFloat bottom = (velocity.y > 0) ? velocity.y : 0;
    
    if (started == YES)
        return;
    
    if (left > right && left > top && left > bottom) {
        started = YES;
        [self killToDirection:MessageViewDirectionLeft completion:completion];
    }
    else if (right > left && right > top && right > bottom) {
        started = YES;
        [self killToDirection:MessageViewDirectionRight completion:completion];
    }
    else if (top > left && top > right && top > bottom) {
        started = YES;
        [self killToDirection:MessageViewDirectionTop completion:completion];
    }
    else if (bottom > left && bottom > top && bottom > right) {
        started = YES;
        [self killToDirection:MessageViewDirectionTop completion:completion];
    }
}

- (void)dealloc
{
    __LF
}

- (void)tapped:(UITapGestureRecognizer*)tap
{
    if (self.cancel) {
        self.cancel();
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self kill];
    });
}

- (CGFloat)w
{
    return CGRectGetWidth(mainWindow.bounds);
}

- (CGFloat)h
{
    CGFloat h = self.statusBarHeight;
    
    if (self.customView) {
        h += self.vInset;
        h += CGRectGetHeight(self.customView.bounds);
        h += self.vInset;
    }
    else {
        h += self.vInset;
        h += self.titleHeight;
        h += [self.message heightWithFont:self.messageLabel.font maxWidth:self.textWidth];
        h += self.vInset;
    }
    h += (self.buttonHeight > 0) * (self.vInset + self.buttonHeight);
    
    return h;
}

- (CGFloat)titleHeight
{
    return 30.0f;
}

- (CGFloat)statusBarHeight
{
    return 20.0f;
}

- (void)setCustomView:(UIView *)customView
{
    _customView = customView;
    self.customView.frame = CGRectInset(self.bounds, self.hInset, self.vInset);
    [self addSubview:self.customView];
    [self setNeedsLayout];
}

- (CGFloat)textWidth
{
    return self.w-3*self.hInset;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.frame = CGRectMake(0, 0, self.w, self.h);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.radius].CGPath;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 5.0f;
    self.layer.shadowOpacity = 0.6f;
    
    self.customView.frame = CGRectMake(self.hInset,
                                       self.statusBarHeight+self.vInset,
                                       self.w-2*self.hInset,
                                       self.h-self.statusBarHeight-2*self.vInset);
    
    self.titleLable.frame = CGRectMake(self.hInset*3/2,
                                       self.statusBarHeight,
                                       self.textWidth,
                                       self.titleHeight);
    self.messageLabel.frame = CGRectMake(self.hInset*3/2,
                                         self.statusBarHeight+self.titleHeight,
                                         self.textWidth,
                                         [self.message heightWithFont:self.messageLabel.font maxWidth:self.w - 4*self.hInset]);
    
    __block CGFloat x = self.w - self.hInset/2.f;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton* _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        x -= self.hInset*0.75f;
        x -= CGRectGetWidth(button.bounds);
        CGRect frame = button.frame;
        frame.origin.x = x;
        frame.origin.y = self.h - self.vInset - self.buttonHeight;
        button.frame = frame;
    }];
}

- (void)show
{
    self.frame = [self frameForDirection:self.fromDirection];
    [self setNeedsLayout];
    self.alpha = 0.6;
    [mainWindow addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = self.presentedFrame;
        self.alpha = 1.0f;
    }];
    
    if (self.buttons.count == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self kill];
        });
    }
}

- (void)setTitle:(NSString *)title
{
    self.titleLable.text = title;
}

- (void)setMessage:(NSString *)message
{
    self.messageLabel.text = message;
}

- (NSString *)title
{
    return self.titleLable.text;
}

- (NSString *)message
{
    return self.messageLabel.text;
}

- (void)kill
{
    [self killToDirection:self.toDirection completion:nil];
}

- (void)killToDirection:(MessageViewDirection)direction completion:(VoidBlock)completion
{
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = [self frameForDirection:direction];
        self.alpha = 0.6f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}

- (CGRect)frameForDirection:(MessageViewDirection)direction
{
    CGFloat x = 0, y = 0;
    switch (direction) {
        case MessageViewDirectionLeft:
            x = -self.w;
            y = 0;
            break;
        case MessageViewDirectionTop:
            x = 0;
            y = -self.h;
            break;
        case MessageViewDirectionRight:
            x = self.w;
            y = 0;
            break;
        case MessageViewDirectionBottom:
            x = 0;
            y = CGRectGetHeight(mainWindow.bounds);
            break;
    }
    return CGRectMake(x, y, self.w, self.h);
}

- (CGRect)presentedFrame
{
    return CGRectMake(0, 0, self.w, self.h);
}

- (void)addButton:(NSString*)title
           action:(VoidBlock)handler
  backgroundColor:(UIColor*)backgroundColor
        textColor:(UIColor*)textColor
{
    UIFont *font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    UIButton *button = [UIButton new];
    button.titleLabel.font = font;
    
    self.buttonHeight = [title heightWithFont:font] + 10.f;
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setBackgroundColor:backgroundColor ? backgroundColor : [UIColor clearColor]];
    [button setTitleColor:textColor ? textColor : [UIColor whiteColor] forState:UIControlStateNormal];
    [button setRadius:4.f];
    [button setClipsToBounds:YES];
    [button setFrame:CGRectMake(0, 0, [title widthWithFont:font]+16.f, self.buttonHeight)];
    [button addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    
    if (handler) {
        [self.handlers setObject:handler forKey:title];
    }
    [self.buttons addObject:button];
}

- (void)addCancelButton:(NSString*)title
                 action:(VoidBlock)handler
        backgroundColor:(UIColor*)backgroundColor
              textColor:(UIColor*)textColor
{
    if (handler) {
        self.cancel = handler;
    }
    [self addButton:title ? title : @"CANCEL"
             action:handler
    backgroundColor:backgroundColor ? backgroundColor : [UIColor femaleColor]
          textColor:textColor];
}


- (void) tappedButton:(UIButton*)sender
{
    __LF
    id title = sender.titleLabel.text;
    VoidBlock handler = [self.handlers objectForKey:title];
    if (handler) {
        handler();
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self kill];
    });
}

@end
