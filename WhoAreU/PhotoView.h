//
//  PhotoView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 3. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserView : UIView
@property (strong, nonatomic) User *user;
- (void) clear;
- (void) updateMediaOnViewController:(UIViewController*)viewController;
@end

@interface PhotoView : UIView
@property (strong, nonatomic) IBInspectable UIImage* image;
@property (strong, nonatomic) Media* media;
- (void) clear;
- (void) updateMediaOnViewController:(UIViewController*)viewController;
- (void) setUser:(User *)user;
- (void) setMediaDic:(MediaDic *)mediaDic;
@end
