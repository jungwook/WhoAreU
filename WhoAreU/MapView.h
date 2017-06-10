//
//  MapView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapView : UIView <MKMapViewDelegate>
@property (nonatomic, strong) User* user;
@property (nonatomic, strong) NSString *userAddress;
@property (nonatomic, strong) NSString *myAddress;
@property (copy, nonatomic) UserViewRectBlock photoAction;
@end
