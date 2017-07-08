//
//  Collection.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 1..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Collection.h"

@interface Collection()
{
    CGFloat contentOffset;
}
@end

@implementation Collection

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview == nil) {
        [self removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];    
    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentOffset];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    static UICollectionViewCell *prevCell = nil;
    if (context == &contentOffset) {
        UICollectionViewCell *cell = self.visibleCell;
        if (cell != prevCell) {
            prevCell = cell;
            if (self.visibleCellChangedBlock) {
                self.visibleCellChangedBlock(cell);
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
