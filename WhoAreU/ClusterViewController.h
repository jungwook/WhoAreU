//
//  ClusterViewController.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClusterController.h"

typedef struct {
    CLLocationCoordinate2D sw;
    CLLocationCoordinate2D ne;
} PointBox;


@interface ClusterViewController : UIViewController

@end

