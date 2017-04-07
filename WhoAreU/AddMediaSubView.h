//
//  AddMediaSubView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 4..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "WelcomeSubViewBase.h"

@protocol DeletableMediaCellDelegate <NSObject>
@required
- (void) deleteUserMedia:(Media*)media;
@end

@protocol AddMediaCellDelegate <NSObject>
@required
- (void) addMedia;

@end

@interface AddMediaSubView : WelcomeSubViewBase <UICollectionViewDelegate, UICollectionViewDataSource>

@end
