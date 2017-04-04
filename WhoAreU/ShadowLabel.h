//
//  ShadowLabel.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShadowLabel : UILabel

@property CGFloat   shadeOpacity;
@property CGSize    shadeOffset;
@property UIColor   *shadeColor;
@property CGFloat   shadeRadius;

- (void)update;
@end
