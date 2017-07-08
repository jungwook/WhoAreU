//
//  TabBar.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 20..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kTabBarIndicatorPositionNone,
    kTabBarIndicatorPositionTop,
    kTabBarIndicatorPositionBottom,
} TabBarIndicatorPosition;

@interface TabBar : UIView
@property (nonatomic, strong) NSArray <NSDictionary*> *items;
@property (nonatomic) NSUInteger index;
@property (nonatomic, copy) IndexBlock selectAction;
@property (nonatomic, strong) IBInspectable UIColor *indicatorColor;
@property (nonatomic) IBInspectable TabBarIndicatorPosition position;
@property (nonatomic, strong) IBInspectable UIColor *selectedColor, *deselectedColor;
@property (nonatomic) IBInspectable BOOL gradientOn;
@property (nonatomic) IBInspectable BOOL blurOn;
@property (nonatomic) IBInspectable BOOL equalWidth;
@property (nonatomic) IBInspectable BOOL smallFonts;
@property (nonatomic) IBInspectable UIBlurEffectStyle blurStyle;

@property (nonatomic, readonly) UIFont *font, *selectedFont, *smallFont, *selectedSmallFont;

- (void)addItem:(NSDictionary*)item;
- (void)updateItem:(NSDictionary*)item atIndex:(NSUInteger)index;
@end
