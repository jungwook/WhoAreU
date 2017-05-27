//
//  DropDownNavigationItem.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 27..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropDownNavigationItem : UINavigationItem
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, copy) IndexBlock action;
@end
