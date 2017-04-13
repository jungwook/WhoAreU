//
//  Menus.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 12..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FloatingDrawerViewController.h"

@interface Menus : FloatingDrawerViewController
@property (nonatomic, strong) NSDictionary* screens;
- (void) selectScreenWithID:(NSString*) screen;
- (void) toggleMenuWithScreenID:(NSString *)screen;
- (void) toggleMenu;
@end
