//
//  Extensions.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#ifndef Extensions_h
#define Extensions_h

#import <UIKit/UIKit.h>

@interface UIView(Extras)
@property (nonatomic) IBInspectable CGFloat radius;
@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat shadowRadius;
@end

@interface UILabel(Shadow)
@property (nonatomic) IBInspectable BOOL shadow;
@end

#endif /* Extensions_h */
