//
//  ModalViewController.h
//  WithMe
//
//  Created by 한정욱 on 2016. 8. 19..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModalViewController : UIViewController <UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>
@property (nonatomic, readonly) CGFloat offsetHeight;
@end

@interface Interactor : UIPercentDrivenInteractiveTransition
@property (nonatomic) BOOL started, shouldFinish;

@end
