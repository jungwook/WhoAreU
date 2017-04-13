//
//  FloatingDrawerViewController.h
//  JVFloatingDrawer
//
//  Created by Julian Villella on 2015-01-11.
//  Copyright (c) 2015 JVillella. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FloatingDrawerAnimation;

typedef NS_ENUM(NSInteger, FloatingDrawerSide) {
    FloatingDrawerSideNone = 0,
    FloatingDrawerSideLeft,
    FloatingDrawerSideRight
};

@interface FloatingDrawerViewController : UIViewController

#pragma mark - Managed View Controllers

@property (nonatomic, strong) UIViewController *centerViewController;
@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) UIViewController *rightViewController;

#pragma mark - Reveal Widths

@property (nonatomic, assign) CGFloat leftDrawerWidth;
@property (nonatomic, assign) CGFloat rightDrawerWidth;

#pragma mark - Interaction

@property (nonatomic, assign, getter=isDragToRevealEnabled) BOOL dragToRevealEnabled;

- (void)openDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated
                completion:(void(^)(BOOL finished))completion;

- (void)closeDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated
                 completion:(void(^)(BOOL finished))completion;

- (void)toggleDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated
                  completion:(void(^)(BOOL finished))completion;

#pragma mark - Animation

@property (nonatomic, strong) id<FloatingDrawerAnimation> animator;

#pragma mark - Background

@property (nonatomic, strong) UIImage *backgroundImage;

@end
