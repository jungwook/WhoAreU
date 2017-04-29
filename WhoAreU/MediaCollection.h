//
//  MediaCollection.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 23..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaCollection : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak) User* user;
@property (nonatomic, weak) UIViewController* parent;
- (void) addMedia;
@end
