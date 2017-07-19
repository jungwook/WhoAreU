//
//  PageTab.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageTab : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) UIPageViewController *pages;
@end
