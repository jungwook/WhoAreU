//
//  ClusterViewController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 14..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ClusterViewController.h"
#import "ClusterAnnotation.h"
#import "FBClusteringManager.h"
#import "FloatingActionButton.h"

@interface ClusterViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) ClusterController *cluster;
@property (nonatomic, strong) FBClusteringManager *manager;
@property (nonatomic, strong) NSMutableArray <id> *annotations;
@property (nonatomic, strong) ObjectAnnotation *selectedAnnotation;
@end

@implementation ClusterViewController

-(void)viewWillAppear:(BOOL)animated
{
    __LF
}

- (void)viewDidAppear:(BOOL)animated
{
    __LF
}

-(void)viewWillDisappear:(BOOL)animated
{
    __LF
}

- (void)viewDidDisappear:(BOOL)animated
{
    __LF
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.annotations = [NSMutableArray new];
    
    self.mapView.pitchEnabled = YES;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    
    self.manager = [FBClusteringManager new];
    [self loadUserObjects];
    
    FloatingActionButton *button = [FloatingActionButton new];
    [button setTitle:@"+" forState:UIControlStateNormal];
    
    CGRect frame = button.frame;
    frame.origin.x = 20;
    frame.origin.y = 40;
    
    button.frame = frame;
    
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        
        NSArray *annotations = [self.manager clusteredAnnotationsWithinMapRect:mapView.visibleMapRect withZoomScale:scale];
        [self.manager displayAnnotations:annotations onMapView:mapView];
    }];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[ClusterAnnotationView class]]) {
        FBAnnotationCluster *annotation = view.annotation;
        [mapView showAnnotations:annotation.annotations animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[FBAnnotationCluster class]]) {
        ClusterAnnotationView* view = (ClusterAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:ClusterAnnotationView.identifier];
        
        if (view == nil) {
            view = [ClusterAnnotationView viewWithAnnotation:annotation];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    else if ([annotation isKindOfClass:[ObjectAnnotation class]]) {
        ObjectAnnotationView* view = (ObjectAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:LocationAnnotationView.identifier];
        
        if (view == nil) {
            view = [ObjectAnnotationView viewWithAnnotation:annotation];
            [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAnnotationView:)]];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    return nil;
}

- (void)tappedAnnotationView:(UITapGestureRecognizer*)tap
{
    ObjectAnnotationView *view = (id) tap.view;
    ObjectAnnotation *annotation = view.annotation;
    self.selectedAnnotation = annotation;
}

- (void)setSelectedAnnotation:(ObjectAnnotation *)selectedAnnotation
{
    self.selectedAnnotation.highlighted = NO;
    _selectedAnnotation = selectedAnnotation;
    self.selectedAnnotation.highlighted = YES;
    
    [self zoomToUser:self.selectedAnnotation.user];
}

- (void)zoomToUser:(User*)user
{
    CGFloat heading = [[User where] headingToLocation:user.where];
    
    MKMapCamera *camera = [MKMapCamera new];
    camera.centerCoordinate = self.selectedAnnotation.coordinate;
    camera.pitch = 70.f;
    camera.heading = heading;
    camera.altitude = 120.0f;
    [self.mapView setCamera:camera animated:YES];
}

- (void)loadUserObjects
{
    PFQuery *query = [User query];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable users,
                                              NSError * _Nullable error)
    {
        [users enumerateObjectsUsingBlock:^(User* _Nonnull user,
                                            NSUInteger idx,
                                            BOOL * _Nonnull stop)
        {
            PFGeoPoint *point = [user objectForKey:fWhere];
            if (point && user) {
                ObjectAnnotation *objectAnnotation = [ObjectAnnotation annotationWithMap:self.mapView objectId:user.objectId user:user];
                [self.annotations addObject:objectAnnotation];
            }
        }];
        [self.manager addAnnotations:self.annotations];
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(37.515791, 127.027807);
        [self.mapView setCenterCoordinate:coords zoomLevel:15 animated:YES];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
