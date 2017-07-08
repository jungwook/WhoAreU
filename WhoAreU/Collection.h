//
//  Collection.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 1..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CellBlock)(__kindof UICollectionViewCell* cell);

@interface Collection : UICollectionView
@property (nonatomic, copy) CellBlock visibleCellChangedBlock;
@end
