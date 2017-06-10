//
//  CompassView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CompassView : UIView
@property (nonatomic) CGFloat heading;
@property (nonatomic, strong) IBInspectable UIColor*compassColor, *textColor, *pointerColor;
@end
