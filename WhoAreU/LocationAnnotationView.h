//
//  LocationAnnotationView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "IndentedLabel.h"

@class LocationAnnotationView;

@interface LocationAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL highlighted;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, weak) MKMapView *parent;
@property (nonatomic, readonly) LocationAnnotationView* view;
+ (instancetype)annotationWithMap:(MKMapView*)map andUser:(User *)user;
@end

@interface LocationAnnotationView : MKAnnotationView
@property (nonatomic, readonly) UIImage *photo;
@property (nonatomic, readonly) LocationAnnotation* locationAnnotation;

+ (id)identifier;
+ (instancetype) viewWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation;
- (id)initWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation;
@end
