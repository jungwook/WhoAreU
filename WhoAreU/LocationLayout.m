//
//  LocationLayout.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LocationLayout.h"

@implementation LocationLayout

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)offset
                                 withScrollingVelocity:(CGPoint)velocity {
    __LF
    CGRect cvBounds = self.collectionView.bounds;
    CGFloat halfWidth = cvBounds.size.width * 0.5f;
    CGFloat proposedContentOffsetCenterX = offset.x + halfWidth;
    
    NSArray* attributesArray = [self layoutAttributesForElementsInRect:cvBounds];
    
    UICollectionViewLayoutAttributes* candidateAttributes;
    for (UICollectionViewLayoutAttributes* attributes in attributesArray) {
        
        // == Skip comparison with non-cell items (headers and footers) == //
        if (attributes.representedElementCategory !=
            UICollectionElementCategoryCell) {
            continue;
        }
        
        // == First time in the loop == //
        if(!candidateAttributes) {
            candidateAttributes = attributes;
            continue;
        }
        
        if (fabs(attributes.center.x - proposedContentOffsetCenterX) <
            fabs(candidateAttributes.center.x - proposedContentOffsetCenterX)) {
            candidateAttributes = attributes;
        }
    }
    
    return CGPointMake(candidateAttributes.center.x - halfWidth, offset.y);
    
}
@end
