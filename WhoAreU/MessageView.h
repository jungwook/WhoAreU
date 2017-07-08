//
//  MessageView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 27..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    MessageViewDirectionTop,
    MessageViewDirectionLeft,
    MessageViewDirectionBottom,
    MessageViewDirectionRight,
} MessageViewDirection;

@interface MessageView : UIView
@property (nonatomic) MessageViewDirection fromDirection;
@property (nonatomic) MessageViewDirection toDirection;
@property (nonatomic) CGFloat hInset, vInset;
@property (nonatomic, strong) IBInspectable NSString *title, *message;
@property (nonatomic) IBInspectable CGFloat seconds;
@property (nonatomic, strong) UIView* customView;
@property (nonatomic) IBInspectable NSTextAlignment alignment;

- (void)addButton:(NSString*)title
           action:(VoidBlock)handler
  backgroundColor:(UIColor*)backgroundColor
        textColor:(UIColor*)textColor;

- (void)addCancelButton:(NSString*)title
                 action:(VoidBlock)handler
        backgroundColor:(UIColor*)backgroundColor
              textColor:(UIColor*)textColor;

- (void)show;
@end
