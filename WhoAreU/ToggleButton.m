//
//  ToggleButton.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 23..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ToggleButton.h"
#import "AppDelegate.h"

typedef void(^BulletBlock)(id bullet);
typedef void (^BulletBlock)(id bullet);

@interface ToggleButton()
@end

@implementation ToggleButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.action = @selector(toggleMenu:);
}

- (void) toggleMenu:(id)sender
{
//    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).menuController toggleMenu];
}

@end
