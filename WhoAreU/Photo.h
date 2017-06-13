//
//  Photo.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 11..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Preview.h"

typedef enum : NSUInteger {
    kPhotoTypeUndefined,
    kPhotoTypeUser,
    kPhotoTypeMedia,
} PhotoType;

@interface Photo : UIView
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) Media *media;
@property (nonatomic) BOOL circle;
@property (nonatomic, readonly) BOOL thumbnail;
@end
