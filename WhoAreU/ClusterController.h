//
//  ClusterController.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClusterAnnotation.h"
#import "LocationAnnotationView.h"

@class ClusterController;

@protocol ClusterControllerDelegate <NSObject>
-(void) loadObjects;
@end

@interface ClusterController : NSObject <MKMapViewDelegate>
@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, readonly) CLLocationCoordinate2D southWest, northEast;
@property (nonatomic, weak) id <ClusterControllerDelegate> delegate;

////////////////////////////////////////////////////////
+ (instancetype) controllerWithMapView:(MKMapView*)mapView
                              delegate:(id<ClusterControllerDelegate>)delegate
                          quadrantSize:(CGSize)size
                               atLeast:(NSUInteger)atleast
                           coverFactor:(CGFloat)factor;
////////////////////////////////////////////////////////

- (void)addObject:(id)object
         objectId:(id)objectId
     atCoordinate:(CLLocationCoordinate2D)coord;

- (void)reloadAnnotations;


@end
