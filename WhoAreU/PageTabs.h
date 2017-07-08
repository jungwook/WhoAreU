//
//  PageTabs.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kTabsIndicatorTop,
    kTabsIndicatorBottom,
} TabsIndicatorType;

@interface PageTabs : UIView
@property (nonatomic, strong) NSArray <NSDictionary*> *items;
@property (nonatomic, copy) IndexBlock selectAction;
@property (nonatomic, strong) IBInspectable UIColor *selectedColor, *defaultColor, *tabColor;
@property (nonatomic) IBInspectable TabsIndicatorType type;
@end
