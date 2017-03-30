//
//  User.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "User.h"

@implementation User
@dynamic nickname, where, whereUdatedAt, age, desc, media, gender;

+ (User *)me
{
    return [User currentUser];
}

@end
