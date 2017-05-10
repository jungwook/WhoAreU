//
//  Nearby.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 18..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kSegmentGirls = 0,
    kSegmentBoys,
    kSegmentAll,
    kSegmentLikes
} SegmentType;

typedef enum : NSUInteger {
    kSectionUsers = 0,
    kSectionLoadMore,
} SectionType;


@interface Nearby : UITableViewController

@end
