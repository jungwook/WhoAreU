//
//  MediaPlayer.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaPlayer : UIView
@property (nonatomic) IBInspectable BOOL muted;
-(void) setMedia:(NSString *)media attachOnView:(UIView*)view;
-(void) stopCurrentPlayback;
@end

@interface VolumeIcon : UIView
@property (nonatomic, strong) IBInspectable UIColor* barColor;
@property (nonatomic) IBInspectable BOOL muted;
@property (nonatomic) BOOL animating;
@property (nonatomic, copy) VoidBlock tappedAction;
@end
