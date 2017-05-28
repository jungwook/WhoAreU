//
//  Compass.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 19..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Compass : UIView
@property (nonatomic) IBInspectable CGFloat heading;
@property (nonatomic) IBInspectable CGFloat lineWidth;
@property (strong, nonatomic) IBInspectable UIColor *lineColor;
@property (strong, nonatomic) IBInspectable UIColor *paneColor;
@property (strong, nonatomic) IBInspectable UIColor *northColor;
@end
