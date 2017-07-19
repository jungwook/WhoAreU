//
//  FloatingActionButton.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 17..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kFloatingMenuDirectionAny,
    kFloatingMenuDirectionUp,
    kFloatingMenuDirectionDown,
    kFloatingMenuDirectionLeft,
    kFloatingMenuDirectionRight,
} FloatingMenuDirection;


@interface FloatingActionButtonMenuItem : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *icon;
@end

@interface FloatingActionButton : UIButton

@end
