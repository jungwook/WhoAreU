//
//  BlurView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlurView : UIView
@property (strong, nonatomic) UIImage* image;
+ (instancetype) viewWithStyle:(UIBlurEffectStyle)style;
@end



