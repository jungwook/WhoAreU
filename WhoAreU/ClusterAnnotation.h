//
//  ClusterAnnotation.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ClusterAnnotationView;

@interface ClusterAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSUInteger count;
@property (nonatomic) BOOL highlighted;
@property (nonatomic) CGSize quadrantSize;
@property (nonatomic, weak) MKMapView *parent;
@property (nonatomic, readonly) ClusterAnnotationView* view;
+ (instancetype)annotationWithMap:(MKMapView *)mapView
                     quadrantSize:(CGSize)size
                            count:(NSUInteger)count
                       coordinate:(CLLocationCoordinate2D)coords;
@end

@interface ClusterAnnotationView : MKAnnotationView
@property (nonatomic, readonly) ClusterAnnotation* clusterAnnotation;

+ (id)identifier;
+ (instancetype) viewWithAnnotation:(ClusterAnnotation<MKAnnotation>*)annotation;
- (id)initWithAnnotation:(ClusterAnnotation<MKAnnotation>*)annotation;
@end



@class ObjectAnnotationView;

@interface ObjectAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL highlighted;
@property (nonatomic, strong) id objectId;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, weak) MKMapView *parent;
@property (nonatomic, readonly) ObjectAnnotationView* view;

+ (instancetype)annotationWithMap:(MKMapView*)mapView
                         objectId:(id)objectId
                             user:(User *)user;
@end

@interface ObjectAnnotationView : MKAnnotationView
@property (nonatomic, readonly) UIImage *photo;
@property (nonatomic, readonly) ObjectAnnotation* objectAnnotation;

+ (id)identifier;
+ (instancetype) viewWithAnnotation:(ObjectAnnotation<MKAnnotation>*)annotation;
- (id)initWithAnnotation:(ObjectAnnotation<MKAnnotation>*)annotation;
@end

