//
//  Preview.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 2..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewMedia : UIView
+ (void)showMedia:(Media*)media;
@end

@interface PreviewUser : UIView
+ (void)showUser:(User*)user;
@end
