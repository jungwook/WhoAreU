//
//  ClusterController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ClusterController.h"

#define QuadrantSize CGSizeMake(50, 50);

@interface Quadrant : NSObject
@property (nonatomic, strong) NSMutableDictionary *objects;
@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
@end

@implementation Quadrant

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.objects = [NSMutableDictionary dictionary];
    self.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
}

- (void)dealloc
{
    [self.objects removeAllObjects];
    self.objects = nil;
}

- (void)addObject:(id)object objectId:(id)objectId at:(CLLocationCoordinate2D)coord
{
    _centerCoordinate = CLLocationCoordinate2DMake(_centerCoordinate.latitude+coord.latitude, _centerCoordinate.longitude+coord.longitude);
    
    [self.objects setObject:object forKey:objectId];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    NSUInteger count = self.objects.count;
    if (count) {
        return CLLocationCoordinate2DMake(_centerCoordinate.latitude/(CLLocationDegrees)count, _centerCoordinate.longitude/(CLLocationDegrees)count);
    }
    else {
        return _centerCoordinate;
    }
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"Q@(%.5f,%.5f) W %ld objects", self.centerCoordinate.latitude, self.centerCoordinate.longitude, self.objects.count];
}

@end

@interface ClusterController ()
@property (nonatomic) CGSize quadrantSize;
@property (nonatomic) NSUInteger atLeast;
@property (nonatomic) CGFloat factor;
@property (nonatomic) CGPoint topleft, bottomright;
@property (nonatomic) CLLocationCoordinate2D maxSouthWest, maxNorthEast;

@property (nonatomic, strong) NSMutableDictionary <id, Quadrant *> *quadrants;
@property (nonatomic, strong) NSMutableArray *objects;
@end

@implementation ClusterController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.quadrants = [NSMutableDictionary dictionary];
    self.objects = [NSMutableArray array];
    
    self.maxSouthWest = CLLocationCoordinate2DMake(FLT_MAX, FLT_MAX);
    self.maxNorthEast = CLLocationCoordinate2DMake(-FLT_MAX, -FLT_MAX);
}

+ (instancetype)controllerWithMapView:(MKMapView *)mapView
                             delegate:(id<ClusterControllerDelegate>)delegate
                         quadrantSize:(CGSize)size
                              atLeast:(NSUInteger)atleast
                          coverFactor:(CGFloat)factor
{
    ClusterController *controller = [ClusterController new];
    controller.mapView = mapView;
    controller.delegate = delegate;
    controller.factor = factor;
    controller.atLeast = atleast;
    controller.quadrantSize = size;
    return controller;
}

- (void)setQuadrantSize:(CGSize)quadrantSize
{
    _quadrantSize = quadrantSize;

    CGFloat width = CGRectGetWidth(self.mapView.bounds), height = CGRectGetHeight(self.mapView.bounds);

    self.topleft = CGPointMake(-self.factor*width, -self.factor*height);
    self.bottomright = CGPointMake((1+self.factor)*width, (1+self.factor)*height);
    
    NSLog(@"topleft %@ bottomright %@ %.0f,%.0f", NSStringFromCGPoint(self.topleft), NSStringFromCGPoint(self.bottomright), width, height);
}

-(void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.mapView.delegate = self;
}

- (void)addObject:(id)object
         objectId:(id)objectId
     atCoordinate:(CLLocationCoordinate2D)coord
{
    id obj = @{
               @"objectId" : objectId,
               @"object" : object,
               @"latitude" : @(coord.latitude),
               @"longitude" : @(coord.longitude),
               };
    [self.objects addObject:obj];
}

- (void)dealloc
{
    self.quadrants = nil;
}

- (NSIndexPath*) indicesForCoordinates:(CLLocationCoordinate2D)coords
{
    CGPoint pointInMap = [self.mapView convertCoordinate:coords toPointToView:self.mapView];
    CGFloat width = self.bottomright.x - self.topleft.x;
    CGFloat height = self.bottomright.y - self.topleft.y;
    CGFloat xoffset = pointInMap.x - self.topleft.x;
    CGFloat yoffset = pointInMap.y - self.topleft.y;

    NSUInteger horizontals = 1+width/self.quadrantSize.width;
    NSUInteger verticals = 1+height/self.quadrantSize.height;

    NSUInteger xd = floor(horizontals * xoffset / width), yd = floor(verticals * yoffset / height);
    
    return [NSIndexPath indexPathForItem:xd inSection:yd];
}

- (void)reloadAnnotations
{
    __block NSUInteger clusters = 0;
    
    [self.quadrants removeAllObjects];
    [self.objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id objectId = [obj objectForKey:@"objectId"];
        id object = [obj objectForKey:@"object"];
        CLLocationDegrees latitude = [[obj objectForKey:@"latitude"] floatValue];
        CLLocationDegrees longitude = [[obj objectForKey:@"longitude"] floatValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
        
        NSIndexPath *indexPath = [self indicesForCoordinates:coord];
        Quadrant *quadrant = [self.quadrants objectForKey:indexPath];
        if (quadrant == nil) {
            quadrant = [Quadrant new];
            [self.quadrants setObject:quadrant forKey:indexPath];
        }
        [quadrant addObject:object objectId:objectId at:coord];
    }];
    
    CGFloat zoom = self.mapView.zoomLevel;
//    [self.mapView removeAnnotations:self.mapView.annotations];
//    [self.quadrants enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, Quadrant * _Nonnull quadrant, BOOL * _Nonnull stop) {
//        NSUInteger count = quadrant.objects.count;
//        if (count > self.atLeast && zoom < 15.f) {
//            clusters++;
//            CLLocationCoordinate2D coords = quadrant.centerCoordinate;
//            ClusterAnnotation *annotation = [ClusterAnnotation annotationWithMap:self.mapView
//                                                                    quadrantSize:self.quadrantSize
//                                                                           count:count
//                                                                      coordinate:coords];
//            [self.mapView addAnnotation:annotation];
//        }
//        else {
//            [quadrant.objects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull objectId, id  _Nonnull object, BOOL * _Nonnull stop) {
//                ObjectAnnotation *objectAnnotation = [ObjectAnnotation annotationWithMap:self.mapView
//                                                                                objectId:objectId
//                                                                                    user:object];
//                [self.mapView addAnnotation:objectAnnotation];
//            }];
//        }
//    }];
//
//    NSLog(@"There are %ld quads with %ld clusters and a total of %ld annotations", self.quadrants.count, clusters, self.mapView.annotations.count);
//
//    return;
//    
    
    NSDictionary *annotations = [self objectAnnotations];
    NSMutableDictionary *newAnnotations = [NSMutableDictionary dictionary];
    NSMutableArray <ObjectAnnotation*>*toDelete = [NSMutableArray array];
    NSMutableArray <ObjectAnnotation*>*toAdd = [NSMutableArray array];
    
    [self removeClusterAnnotations];
    [self.quadrants enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, Quadrant * _Nonnull quadrant, BOOL * _Nonnull stop) {
        NSUInteger num = quadrant.objects.count;
        if (num > self.atLeast && zoom < 15.f) {
            clusters++;
            
            ClusterAnnotation *annotation = [ClusterAnnotation annotationWithMap:self.mapView
                                                                    quadrantSize:self.quadrantSize
                                                                           count:num
                                                                      coordinate:quadrant.centerCoordinate];
            [self.mapView addAnnotation:annotation];
        }
        else {
            [quadrant.objects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull objectId, id  _Nonnull object, BOOL * _Nonnull stop) {

                ObjectAnnotation *objectAnnotation = [ObjectAnnotation annotationWithMap:self.mapView objectId:objectId user:object];
                [newAnnotations setObject:objectAnnotation forKey:objectId];
            }];
        }
    }];
    
    [newAnnotations.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotations.allKeys containsObject:key] == NO) {
            [toAdd addObject:[newAnnotations objectForKey:key]];
        }
    }];
    
    [annotations.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([newAnnotations.allKeys containsObject:key] == NO) {
            [toDelete addObject:[annotations objectForKey:key]];
        }
    }];
    
    [toDelete enumerateObjectsUsingBlock:^(ObjectAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.mapView removeAnnotation:annotation];
    }];
    
    [toAdd enumerateObjectsUsingBlock:^(ObjectAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.mapView addAnnotation:annotation];
    }];
    
}

- (BOOL)annotations:(NSMutableArray*)annotations containsObjectId:(id)objectId
{
    __block BOOL ret = NO;
    
    [annotations enumerateObjectsUsingBlock:^(id  _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotation isKindOfClass:[ObjectAnnotation class]]) {
            ObjectAnnotation *object = annotation;
            if ([objectId isEqualToString:object.objectId]) {
                ret = YES;
                *stop = YES;
            }
        }
    }];
    return ret;
}

- (NSDictionary*)objectAnnotations
{
    NSMutableDictionary *annotations = [NSMutableDictionary dictionary];
    
    [self.mapView.annotations enumerateObjectsUsingBlock:^(id<MKAnnotation> _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotation isKindOfClass:[ObjectAnnotation class]]) {
            ObjectAnnotation *objectAnnotation = annotation;
            [annotations setObject:objectAnnotation forKey:objectAnnotation.objectId];
        }
    }];
    return annotations;
}

- (void)removeClusterAnnotations
{
    [self.mapView.annotations enumerateObjectsUsingBlock:^(id _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }];
}

- (CLLocationCoordinate2D)southWest
{
    CGFloat w = CGRectGetWidth(self.mapView.bounds), h = CGRectGetHeight(self.mapView.bounds);
    
    CGPoint sw = CGPointMake(-self.factor*w, (1+self.factor)*h);
    return [self.mapView convertPoint:sw toCoordinateFromView:self.mapView];
}

- (CLLocationCoordinate2D)northEast
{
    CGFloat w = CGRectGetWidth(self.mapView.bounds), h = CGRectGetHeight(self.mapView.bounds);
    
    CGPoint ne = CGPointMake((1+self.factor)*w, -self.factor*h);
    return [self.mapView convertPoint:ne toCoordinateFromView:self.mapView];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    BOOL enlarged = NO;
    CLLocationCoordinate2D sw = self.southWest, ne = self.northEast;
    if (sw.latitude < self.maxSouthWest.latitude || sw.longitude < self.maxSouthWest.longitude) {
        self.maxSouthWest = sw;
        enlarged = YES;
    }
    if (ne.latitude > self.maxNorthEast.latitude || ne.longitude > self.maxNorthEast.longitude) {
        self.maxNorthEast = ne;
        enlarged = YES;
    }

    if (enlarged && [self.delegate respondsToSelector:@selector(loadObjects)]) {
        NSLog(@"SW:(%.5f,%.5f) NE:(%.5f,%.5f)", self.southWest.latitude, self.southWest.longitude, self.northEast.latitude, self.northEast.longitude);
        [self.objects removeAllObjects];
        [self.delegate loadObjects];
    }
    else {
        [self reloadAnnotations];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        ClusterAnnotationView* view = (ClusterAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:ClusterAnnotationView.identifier];
        
        if (!view) {
            view = [ClusterAnnotationView viewWithAnnotation:annotation];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    else if ([annotation isKindOfClass:[ObjectAnnotation class]]) {
        ObjectAnnotationView* view = (ObjectAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:LocationAnnotationView.identifier];
        
        if (!view) {
            view = [ObjectAnnotationView viewWithAnnotation:annotation];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    return nil;
}


@end
