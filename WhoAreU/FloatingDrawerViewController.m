//
//  FloatingDrawerViewController.m
//  JVFloatingDrawer
//
//  Created by Julian Villella on 2015-01-11.
//  Copyright (c) 2015 JVillella. All rights reserved.
//

#import "FloatingDrawerViewController.h"
#import "FloatingDrawerView.h"
#import "FloatingDrawerAnimation.h"

NSString *FloatingDrawerSideString(FloatingDrawerSide side) {
    const char* c_str = 0;
#define PROCESS_VAL(p) case(p): c_str = #p; break;
    switch(side) {
        PROCESS_VAL(FloatingDrawerSideNone);
        PROCESS_VAL(FloatingDrawerSideLeft);
        PROCESS_VAL(FloatingDrawerSideRight);
    }
#undef PROCESS_VAL
    
    return [NSString stringWithCString:c_str encoding:NSASCIIStringEncoding];
}

@interface FloatingDrawerViewController ()

@property (nonatomic, strong, readonly) FloatingDrawerView *drawerView;
@property (nonatomic, assign) FloatingDrawerSide currentlyOpenedSide;
@property (nonatomic, strong) UITapGestureRecognizer *toggleDrawerTapGestureRecognizer;

@end

@implementation FloatingDrawerViewController

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.currentlyOpenedSide = FloatingDrawerSideNone;
}

#pragma mark - View Related

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)loadView {
    self.drawerView = [[FloatingDrawerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

// Convenience type-wrapper around self.view. Maybe not the best idea?
- (void)setDrawerView:(FloatingDrawerView *)drawerView {
    self.view = drawerView;
}

- (FloatingDrawerView *)drawerView {
    return (FloatingDrawerView *)self.view;
}

#pragma mark - Interaction

- (void)openDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated completion:(void(^)(BOOL finished))completion {
    if(self.currentlyOpenedSide != drawerSide) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:drawerSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        // First close opened drawer and then open new drawer
        if(self.currentlyOpenedSide != FloatingDrawerSideNone) {
            [self closeDrawerWithSide:self.currentlyOpenedSide animated:animated completion:^(BOOL finished) {
                [self.animator presentationWithSide:drawerSide sideView:sideView centerView:centerView animated:animated completion:completion];
            }];
        } else {
            [self.animator presentationWithSide:drawerSide sideView:sideView centerView:centerView animated:animated completion:completion];
        }
        
        [self addDrawerGestures];
        [self.drawerView willOpenFloatingDrawerViewController:self];
    }
    
    self.currentlyOpenedSide = drawerSide;
}

- (void)closeDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated completion:(void(^)(BOOL finished))completion {
    if(self.currentlyOpenedSide == drawerSide && self.currentlyOpenedSide != FloatingDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:drawerSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator dismissWithSide:drawerSide sideView:sideView centerView:centerView animated:animated completion:completion];
        
        self.currentlyOpenedSide = FloatingDrawerSideNone;
        
        [self restoreGestures];
        
        [self.drawerView willCloseFloatingDrawerViewController:self];
    }
}

- (void)toggleDrawerWithSide:(FloatingDrawerSide)drawerSide animated:(BOOL)animated completion:(void(^)(BOOL finished))completion {
    if(drawerSide != FloatingDrawerSideNone) {
        if(drawerSide == self.currentlyOpenedSide) {
            [self closeDrawerWithSide:drawerSide animated:animated completion:completion];
        } else {
            [self openDrawerWithSide:drawerSide animated:animated completion:completion];
        }
    }
}

#pragma mark - Gestures

- (void)addDrawerGestures {
    self.centerViewController.view.userInteractionEnabled = NO;
    self.toggleDrawerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionCenterViewContainerTapped:)];
    [self.drawerView.centerViewContainer addGestureRecognizer:self.toggleDrawerTapGestureRecognizer];
}

- (void)restoreGestures {
    [self.drawerView.centerViewContainer removeGestureRecognizer:self.toggleDrawerTapGestureRecognizer];
    self.toggleDrawerTapGestureRecognizer = nil;
    self.centerViewController.view.userInteractionEnabled = YES;    
}

- (void)actionCenterViewContainerTapped:(id)sender {
    [self closeDrawerWithSide:self.currentlyOpenedSide animated:YES completion:nil];
}

#pragma mark - Managed View Controllers

- (void)setLeftViewController:(UIViewController *)leftViewController {
    [self replaceViewController:self.leftViewController
             withViewController:leftViewController container:self.drawerView.leftViewContainer];
    
    _leftViewController = leftViewController;
}

- (void)setRightViewController:(UIViewController *)rightViewController {
    [self replaceViewController:self.rightViewController withViewController:rightViewController
                      container:self.drawerView.rightViewContainer];
    
    _rightViewController = rightViewController;
}

- (void)setCenterViewController:(UIViewController *)centerViewController {
    [self replaceViewController:self.centerViewController withViewController:centerViewController
                      container:self.drawerView.centerViewContainer];
    
    _centerViewController = centerViewController;
}

- (void)replaceViewController:(UIViewController *)sourceViewController withViewController:(UIViewController *)destinationViewController container:(UIView *)container {

    [sourceViewController willMoveToParentViewController:nil];
    [sourceViewController.view removeFromSuperview];
    [sourceViewController removeFromParentViewController];
    
    if (destinationViewController) {
        [self addChildViewController:destinationViewController];
        [container addSubview:destinationViewController.view];
   
        UIView *destinationView = destinationViewController.view;
        destinationView.translatesAutoresizingMaskIntoConstraints = NO;
    
        NSDictionary *views = NSDictionaryOfVariableBindings(destinationView);
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[destinationView]|" options:0 metrics:nil views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[destinationView]|" options:0 metrics:nil views:views]];

        [destinationViewController didMoveToParentViewController:self];
    }
}

#pragma mark - Reveal Widths

- (void)setLeftDrawerWidth:(CGFloat)leftDrawerWidth {
    self.drawerView.leftViewContainerWidth = leftDrawerWidth;
}

- (void)setRightDrawerWidth:(CGFloat)rightDrawerWidth {
    self.drawerView.rightViewContainerWidth = rightDrawerWidth;
}

- (CGFloat)leftDrawerRevealWidth {
    return self.drawerView.leftViewContainerWidth;
}

- (CGFloat)rightDrawerRevealWidth {
    return self.drawerView.rightViewContainerWidth;
}

#pragma mark - Background Image

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.drawerView.backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
    return self.drawerView.backgroundImageView.image;
}

#pragma mark - Helpers

- (UIViewController *)viewControllerForDrawerSide:(FloatingDrawerSide)drawerSide {
    UIViewController *sideViewController = nil;
    switch (drawerSide) {
        case FloatingDrawerSideLeft: sideViewController = self.leftViewController; break;
        case FloatingDrawerSideRight: sideViewController = self.rightViewController; break;
        case FloatingDrawerSideNone: sideViewController = nil; break;
    }
    return sideViewController;
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate {
    return [self.centerViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.centerViewController supportedInterfaceOrientations];;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.centerViewController preferredInterfaceOrientationForPresentation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(self.currentlyOpenedSide != FloatingDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:self.currentlyOpenedSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator willRotateOpenDrawerWithOpenSide:self.currentlyOpenedSide sideView:sideView centerView:centerView];
    }
    
    [self.centerViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(self.currentlyOpenedSide != FloatingDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:self.currentlyOpenedSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator didRotateOpenDrawerWithOpenSide:self.currentlyOpenedSide sideView:sideView centerView:centerView];
    }
    
    [self.centerViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Status Bar

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.centerViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.centerViewController;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
