//
//  Preview.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 2..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewMedia : UIView
- (instancetype)initWithMedia:(Media*)media exitWithTap:(BOOL)taps;
- (void) killThisView;
@end

@interface PreviewUser : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
- (instancetype)initWithUser:(User*)user;
@end
