//
//  HeaderMenu.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBar.h"

@interface HeaderMenu : UIView
@property (nonatomic, copy) IndexBlock selectAction;
@property (nonatomic, strong) TabBar *bar;
+ (instancetype) menuWithView:(UIView*)view;
+ (instancetype) menuWithTabBarItems:(NSArray<NSDictionary*>*)items;
@end
