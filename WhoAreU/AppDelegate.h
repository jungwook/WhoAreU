//
//  AppDelegate.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Menus.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) Menus *menuController;

@end

