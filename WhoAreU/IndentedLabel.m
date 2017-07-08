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
        [self setupVariables];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setRounded:(BOOL)rounded
{
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    CGFloat r = MIN(w, h)/2.0f;
    
    self.radius = rounded ? r : rounded;
    self.clipsToBounds = rounded;
}

- (void)setupVariables
{
    self.textInsets = UIEdgeInsetsMake(4, 8, 4, 8);
    [self setNeedsLayout];
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
