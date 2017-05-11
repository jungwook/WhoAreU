//
//  CenterScrollView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 11..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "CenterScrollView.h"

@implementation CenterScrollView

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView* v = [self.delegate viewForZoomingInScrollView:self];
    CGFloat svw = self.bounds.size.width;
    CGFloat svh = self.bounds.size.height;
    CGFloat vw = v.frame.size.width;
    CGFloat vh = v.frame.size.height;
    CGFloat off = 64.0f;
    CGRect f = v.frame;
    
    off = 0.0f;
    
    if (vw < svw)
        f.origin.x = (svw - vw) / 2.0;
    else
        f.origin.x = 0;
    
    if (vh < svh)
        f.origin.y = (svh - vh) / 2.0 - off;
    else
        f.origin.y = -off;
    v.frame = f;
}

@end
