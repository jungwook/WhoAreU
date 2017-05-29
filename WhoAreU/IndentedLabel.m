//
//  IndentedLabel.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 5. 19..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "IndentedLabel.h"

@implementation IndentedLabel

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.textInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.textInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    }
    return self;
}

- (void)layoutSubviews
{
    CGRect rect = self.bounds;
    
    CGFloat w = CGRectGetWidth(rect), h = CGRectGetHeight(rect), m = MIN(w, h)/2.0f;
    
    self.radius = m;
    self.radius = 4.0f;
    self.clipsToBounds = YES;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    UIEdgeInsets insets = self.textInsets;
    
    [self invalidateIntrinsicContentSize];
    CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                    limitedToNumberOfLines:numberOfLines];
    
    rect.origin.x    -= insets.left;
    rect.origin.y    -= insets.top;
    rect.size.width  += (insets.left + insets.right);
    rect.size.height += (insets.top + insets.bottom);
    
    return rect;
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}
@end
