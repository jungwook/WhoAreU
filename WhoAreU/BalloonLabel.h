//
//  BalloonLabel.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kBalloonTypeLeft = 0,
    kBalloonTypeRight,
} BalloonType;

@interface BalloonLabel : UILabel
@property (nonatomic) IBInspectable UIEdgeInsets textInsets;
@property (nonatomic) IBInspectable BalloonType type;
@end
