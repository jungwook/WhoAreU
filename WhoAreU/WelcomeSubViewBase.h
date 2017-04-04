//
//  WelcomeSubViewBase.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeSubViewBase : UIView
@property (nonatomic, copy) StringBlock nextBlock;
@property (nonatomic, copy) VoidBlock prevBlock;
- (void) viewOnTop;
@end
