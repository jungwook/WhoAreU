//
//  SignUp.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 22..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SignUp;

typedef void(^SignUpBlock)(SignUp* viewController, id nickname, id intro, id age, id gender, BOOL mediaSet, MediaType type, NSData *thumbnail, NSData *photo, NSData* movie, SourceType source);

@interface SignUp : UIViewController <UITextFieldDelegate>
@property (nonatomic, copy) SignUpBlock completionBlock;
@property (nonatomic, assign) NSString* info;
@end
