//
//  LocationAnnotationView.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 6..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "IndentedLabel.h"

@interface LocationAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) User *user;
+ (instancetype)annotationWithUser:(User *)user;
@end

@interface LocationAnnotationView : MKAnnotationView
//@property (nonatomic, strong) IndentedLabel *label;
@property (nonatomic, weak) User *user;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic) UIEdgeInsets textInsets;
+ (id)identifier;
+ (instancetype) viewWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation;
- (id)initWithAnnotation:(LocationAnnotation<MKAnnotation>*)annotation;
@end

