//
//  Refresh.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^RefreshBlock)(UIRefreshControl* refreshControl);

@interface Refresh : UIRefreshControl

+ (instancetype)initWithCompletionBlock:(RefreshBlock) completionBlock;

@end
