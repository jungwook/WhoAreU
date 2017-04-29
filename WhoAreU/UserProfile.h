//
//  UserProfile.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalViewController.h"

@interface UserProfile : ModalViewController
@property (nonatomic, weak) User *user;
@end
