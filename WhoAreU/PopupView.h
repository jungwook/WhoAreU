//
//  PopupView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kPopupViewDirectionDown = 0,
    kPopupViewDirectionUp,
} PopupViewDirection;

#define identifierMenuCell @"UITableViewCell.MenuCell"
#define identifierCellContent @"UITableViewCellContentView"
#define identifierErrorMessage @"PopupMenu: unknown sender class to start menu."


@interface PopupView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBInspectable UIFont* font;
@property (nonatomic, strong) IBInspectable UIFont * headerFont;
@property (nonatomic, strong) UIView* view;
@property (nonatomic, strong) UIColor* backgroundColor;

+ (void) showFromView:(id)sender
                 view:(UIView*)view
                  end:(VoidBlock)cancel;

+ (void) showFromFrame:(CGRect)frame
                  view:(UIView*)view
                   end:(VoidBlock)cancel;

@end
