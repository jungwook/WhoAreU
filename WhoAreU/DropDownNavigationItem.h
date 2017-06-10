//
//  DropDownNavigationItem.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 27..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropDownNavigationItem : UINavigationItem
@property (nonatomic, strong) id menuItems;
@property (nonatomic, copy) SectionIndexBlock action;
@property (nonatomic, strong) IBInspectable UIColor *textColor, *pointerColor;
@property (nonatomic, strong) IBInspectable UIFont *font;

@end
