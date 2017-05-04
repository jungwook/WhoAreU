//
//  Balloon.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 31..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndentedLabel.h"

#define LEFTBUTSIZE 45
#define INSET 8
#define HINSET 4
#define SENDBUTSIZE 50
#define LINEHEIGHT 17
#define TEXTVIEWHEIGHT 48

#define CHATMAXWIDTH 200
#define MEDIASIZE 160

#define PHOTOVIEWSIZE 30

#define chatFont [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]

typedef enum : NSUInteger {
    kBalloonTypeLeft = 0,
    kBalloonTypeRight,
} BalloonType;

@interface Balloon : UIView
@property (nonatomic, weak) UIViewController* parent;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat ballonInset;
@property (nonatomic, weak) MessageDic* message;
@property (nonatomic, strong) UIColor *rightColor, *leftColor;
@property (nonatomic) BalloonType type;
@end
