//
//  SignupAndLogin.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupAndLogin : UIViewController
@property (nonatomic, copy) VoidBlock successHandler;
@property (nonatomic, copy) ErrorBlock failureHandler;
@end
