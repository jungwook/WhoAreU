//
//  Refresh.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Refresh.h"

@interface Refresh()
@property (nonatomic, strong) RefreshBlock action;
@end

@implementation Refresh


+ (instancetype)initWithCompletionBlock:(RefreshBlock)completionBlock
{
    return [[Refresh alloc] initWithCompletionBlock:completionBlock];
}

- (instancetype)initWithCompletionBlock:(RefreshBlock)action
{
    self = [super init];
    if (self) {
        self.action = action;
        [self addTarget:self action:@selector(refreshPage) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)refreshPage
{
    if (self.action) {
        self.action(self);
    }
}
@end
