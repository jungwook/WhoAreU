//
//  PopupMenu.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 26..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kPopupMenuDirectionDown = 0,
    kPopupMenuDirectionUp,
} PopupMenuDirection;

@interface PopupMenu : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBInspectable UIFont* font;
@property (nonatomic, strong) NSArray* menuItems;
@property (nonatomic, strong) NSArray* icons;
@property (nonatomic, strong) UIColor *separatorColor, *textColor, *backgroundColor;
@property (nonatomic) NSTextAlignment textAlignment;

- (instancetype)initWithMenuItems:(NSArray*)menuItems;

- (instancetype)initWithMenuItems:(NSArray*)menuItems
                            icons:(NSArray*)icons;

+ (void) showFromView:(id)sender
            menuItems:(NSArray*)menuItems
                icons:(NSArray*)icons
           completion:(IndexBlock)completion
               cancel:(VoidBlock)cancel;

+ (void) showFromView:(id)sender
            menuItems:(NSArray*)menuItems
           completion:(IndexBlock)completion
               cancel:(VoidBlock)cancel;

+ (void) showFromFrame:(CGRect)frame
             menuItems:(NSArray*)menuItems
            completion:(IndexBlock)completion
                cancel:(VoidBlock)cancel;

+ (void) showFromFrame:(CGRect)frame
             menuItems:(NSArray*)menuItems
                 icons:(NSArray*)icons
            completion:(IndexBlock)completion
                cancel:(VoidBlock)cancel;

@end
