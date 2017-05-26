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
@property (nonatomic) IBInspectable BalloonType type;
@property (nonatomic) IBInspectable CGFloat pointerInset, cornerRadius, verticalSpacing, horizontalSpacing;
@property (nonatomic) CGFloat mediaWidth;
- (void) setMediaFile:(id)mediaFile;
@end
