//
//  FloatingActionButton.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 17..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "FloatingActionButton.h"
#import "MaterialPalettes.h"
#import "MDCInkLayer.h"


@interface FloatingActionButton ()
@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) UIView *backgroundView, *snapshot, *circle;
@property (nonatomic, strong) MDCInkLayer *inkLayer;

@property (nonatomic, strong) NSMutableArray <NSDictionary*> *items;
@end

@implementation FloatingActionButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.items = [NSMutableArray new];
    
    super.backgroundColor = [UIColor clearColor];
    
    self.frame = CGRectMake(0, 0, 40, 40);
    [self setNeedsLayout];
    
    self.backgroundLayer = [CALayer layer];
    self.backgroundColor = [MDCPalette redPalette].tint400;
    self.backgroundLayer.cornerRadius = self.bounds.size.width/2.f;
    self.backgroundLayer.masksToBounds = YES;
    
    [self.layer addSublayer:self.backgroundLayer];
    
    self.backgroundView = [UIView new];
    self.backgroundView.frame = mainWindow.bounds;
    self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    self.inkLayer = [MDCInkLayer new];
    self.inkLayer.bounded = NO;
    self.inkLayer.frame = mainWindow.bounds;
    self.inkLayer.inkColor = [UIColor blackColor];
    [self.backgroundView.layer addSublayer:self.inkLayer];
    
    self.circle = [UIView new];
    self.circle.backgroundColor = self.backgroundColor;
    self.circle.radius = 20;
    self.circle.clipsToBounds = YES;
    self.circle.frame = self.frame;
    
    [self.backgroundView addSubview:self.circle];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundLayer.backgroundColor = backgroundColor.CGColor;
}

- (UIColor *)backgroundColor
{
    return [UIColor colorWithCGColor:self.backgroundLayer.backgroundColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.circle.alpha = 1.0f;
    
    self.snapshot = [self snapshotViewAfterScreenUpdates:NO];

    self.backgroundView.alpha = 0;
    self.snapshot.frame = self.frame;
    self.snapshot.clipsToBounds = NO;
    self.snapshot.layer.shadowPath = nil;
    self.snapshot.layer.shadowColor = nil;
    self.snapshot.layer.shadowRadius = 0;
    [self.backgroundView addSubview:self.snapshot];
    
    [mainWindow addSubview:self.backgroundView];

    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    [self.inkLayer spreadFromPoint:self.circle.frame.origin completion:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.inkLayer evaporateWithCompletion:^{
    }];
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.backgroundView removeFromSuperview];
    }];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(56, 56);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.backgroundLayer.frame = self.bounds;
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(1, 1);
    self.layer.shadowRadius = 5.0f;
    self.layer.shadowOpacity = 0.7f;
    
    self.circle.frame = self.frame;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
