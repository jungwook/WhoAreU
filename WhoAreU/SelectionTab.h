//
//  SelectionTab.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 7..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectionTab : UIView
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      action:(SelectedIndexBlock)action;
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      widths:(NSArray <NSNumber*> *)widths
                      action:(SelectedIndexBlock)action;
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      widths:(NSArray <NSNumber*> *)widths
                   fromColor:(UIColor*)fromColor
                     toColor:(UIColor*)toColor
                      action:(SelectedIndexBlock)action;
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                   fromColor:(UIColor*)fromColor
                     toColor:(UIColor*)toColor
                      action:(SelectedIndexBlock)action;
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      widths:(NSArray <NSNumber*> *)widths
                      colors:(NSArray<UIColor*>*)colors
                      action:(SelectedIndexBlock)action;
+ (instancetype) newWithTabs:(NSArray<NSString*>*)tabs
                      colors:(NSArray<UIColor*>*)colors
                      action:(SelectedIndexBlock)action;

@property (strong, nonatomic) NSMutableArray <NSNumber*> *widths;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic, copy) SelectedIndexBlock selectAction;
@end
