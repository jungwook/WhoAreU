//
//  Segment.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Segment : UIView
@property (nonatomic, strong) IBInspectable NSArray <NSString*> *items;
@property (nonatomic, strong) NSArray <NSNumber*> *widths;
@property (nonatomic, strong) IBInspectable UIFont *font;
@property (nonatomic, strong) IBInspectable UIColor *faceColor;

@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) CGFloat box;
@property (copy, nonatomic) IndexBlock select;

- (void) normalizedWidth;
- (void) equalizeWidth;
@end
