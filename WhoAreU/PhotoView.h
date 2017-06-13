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
- (void) updateMediaOnViewController:(UIViewController *)viewController
                          completion:(ErrorBlock)handler;
- (void) setUserId:(id)userId
     withThumbnail:(id)thumbnail;
@end

@interface PhotoView : UIView
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) IBInspectable UIImage* image;
@property (strong, nonatomic) Media* media;
@property (strong, nonatomic) id dictionary;

- (void) clear;

- (void) updateMediaOnViewController:(UIViewController*)viewController
                          completion:(ErrorBlock)handler;

- (void) setUser:(User *)user;
- (void) setUserId:(id)userId
     withThumbnail:(id)thumbnail;
- (void) setUser:(User*)user
       thumbnail:(id)thumbnail;
@end
