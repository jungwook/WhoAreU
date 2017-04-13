//
//  PhotoView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoView : UIView
@property (strong, nonatomic) IBInspectable UIImage* image;
- (void) setMedia:(Media*)media;
@end
