//
//  MapView.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MapView.h"
#import "IndentedLabel.h"

@interface UserAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) User *user;
- (id)initWithLocation:(CLLocationCoordinate2D)coord;
@end

@interface UserAnnotationView : MKAnnotationView
@property (nonatomic, strong) UIView *ball;
@property (nonatomic, strong) IndentedLabel *label;
@end

@implementation UserAnnotation
- (id)initWithLocation:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
}
@end

@implementation UserAnnotationView

- (id)initWithAnnotation:(UserAnnotation<MKAnnotation>*)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        const CGFloat size = 50,
        x = self.frame.origin.x,
        y = self.frame.origin.y;
        
        self.frame = CGRectMake((x-size)/2.0, (y-size)/2.0f, size, size);
        
        self.ball = [UIView new];
        self.ball.backgroundColor = [UIColor colorWithRed:100/255.f green:167/255.f blue:229/255.f alpha:1];
        self.ball.frame = CGRectMake(0, 0, size, size);
        self.ball.layer.cornerRadius = self.ball.bounds.size.width / 2.0f;
        self.ball.layer.masksToBounds = YES;
        [self.ball drawImage:annotation.image];
        self.ball.borderColor = [UIColor blackColor];
        self.ball.borderWidth = 2.0f;
        
        self.label = [IndentedLabel new];
        self.label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        self.label.text = annotation.user.nickname;
        self.label.backgroundColor = [UIColor blackColor];
        self.label.textColor = [UIColor whiteColor];
        [self.label sizeToFit];
        
        CGFloat w = CGRectGetWidth(self.label.bounds), h = CGRectGetHeight(self.label.bounds);
        
        self.label.frame = CGRectMake((size-w)/2.0f, size+4, w, h);

        [self addSubview:self.ball];
        [self addSubview:self.label];
    }
    return self;
}

@end

@interface MapView()
@property (strong, nonatomic) MKMapView *mapView;
@property (weak, readonly, nonatomic) User *me;
@property (strong, nonatomic) UIImage *userPhoto, *myPhoto;
@property (strong, nonatomic) UIProgressView *progressView;
@property (nonatomic) MKMapRect mapRect;
@end

@implementation MapView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void) initialize
{
    self.mapView = [MKMapView new];
    self.progressView = [UIProgressView new];
    
    self.userAddress = nil;
    self.myAddress = nil;

    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.showsCompass = YES;
    self.mapView.scrollEnabled = YES;
    
    [self.mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMap:)]];
    
    [self addSubview:self.mapView];
    [self addSubview:self.progressView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.mapView.frame = self.bounds;
    self.progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 2.0f);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[UserAnnotation class]])
    {
        UserAnnotationView* pinView = (UserAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"UserAnnotationView"];
        
        if (!pinView)
        {
            pinView = [[UserAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"UserAnnotationView"];
            [pinView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedPhoto:)]];
        }
        else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    CGPoint pointInView = [mapView convertCoordinate:Coords2DFromPoint(self.user.where) toPointToView:self.mapView];
    
    BOOL inside = CGRectContainsPoint(self.mapView.bounds, pointInView);
    
    if (inside == NO && MKMapRectIsNull(self.mapRect) == NO && MKMapRectIsEmpty(self.mapRect) == NO) {
        [self.mapView setRegion:MKCoordinateRegionForMapRect(self.mapRect) animated:YES];
    }
}

- (void)tappedMap:(UITapGestureRecognizer*)sender
{
    __LF
}

- (void)tappedPhoto:(UITapGestureRecognizer*)sender
{
    CGRect rect = [self.mapView convertRect:sender.view.frame toView:mainWindow];
    if (self.photoAction) {
        self.photoAction(self.user, sender.view, rect);
    }
}

- (void)setUserId:(NSString *)userId
{
    if (userId == nil)
        return;
    
    User *user = [User objectWithoutDataWithObjectId:userId];
    
    [user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        self.user = user;
    }];
    
    return;
}

- (void)setUser:(User *)user
{
    _user = user;
    
    NSUInteger tasks = (self.me.where != nil) + (self.user.where != nil) + ( self.user.thumbnail != nil) + (self.me.thumbnail != nil);
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [[self.user fetchIfNeededInBackground] continueWithSuccessBlock:^id _Nullable(BFTask<__kindof PFObject *> * _Nonnull task) {
        CLLocationCoordinate2D userCoords = Coords2DFromPoint(self.user.where);
        CLLocationCoordinate2D myCoords = Coords2DFromPoint(self.me.where);
        self.progressView.alpha = 1.0f;
        
        Counter *counter = [Counter counterWithCount:tasks completion:^{
            dispatch_foreground(^{
                [UIView animateWithDuration:1 animations:^{
                    self.progressView.alpha = 0.0f;
                }];
            });
            self.mapRect = [self mapRectFrom:myCoords to:userCoords];
            [self.mapView setRegion:MKCoordinateRegionForMapRect(self.mapRect) animated:YES];
        }];
        [self.user.where reverseGeocode:^(NSString *string) {
            self.userAddress = string;
            dispatch_foreground(^{
                self.progressView.progress += 1.0/tasks;
            });
            [counter decreaseCount];
        }];
        [self.me.where reverseGeocode:^(NSString *string) {
            self.myAddress = string;
            
            dispatch_foreground(^{
                self.progressView.progress += 1.0/tasks;
            });
            [counter decreaseCount];
        }];
        [S3File getImageFromFile:self.user.thumbnail imageBlock:^(UIImage *image) {
            self.userPhoto = image ? image : [UIImage avatar];
            dispatch_foreground(^{
                self.progressView.progress += 1.0/tasks;
            });
            UserAnnotation *annotation = [[UserAnnotation alloc] initWithLocation:userCoords];
            annotation.user = self.user;
            annotation.image = self.userPhoto;
            
            [self.mapView addAnnotation:annotation];

            [counter decreaseCount];
        }];
        [S3File getImageFromFile:self.me.thumbnail imageBlock:^(UIImage *image) {
            NSLog(@"MY PHOTO DONE");
            self.myPhoto = image ? image : [UIImage avatar];
            
            dispatch_foreground(^{
                self.progressView.progress += 1.0/tasks;
            });
            
            [counter decreaseCount];
        }];
        
        return nil;
    }];
}

- (MKMapRect) mapRectFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to
{
    CGFloat offset = 0.01f, factor = 0.01f;
    NSMutableArray *coords = [NSMutableArray new];
    [coords addObject:[NSValue valueWithMKCoordinate:to]];
    [coords addObject:[NSValue valueWithMKCoordinate:from]];
    [coords addObject:[NSValue valueWithMKCoordinate:CLLocationCoordinate2DMake(to.latitude+offset, to.longitude+offset)]];
    [coords addObject:[NSValue valueWithMKCoordinate:CLLocationCoordinate2DMake(to.latitude-offset, to.longitude-offset)]];
    [coords addObject:[NSValue valueWithMKCoordinate:CLLocationCoordinate2DMake(from.latitude+offset, from.longitude+offset)]];
    [coords addObject:[NSValue valueWithMKCoordinate:CLLocationCoordinate2DMake(from.latitude-offset, from.longitude-offset)]];
    
    MKMapRect zoomRect = MKMapRectNull;
    for (id v in coords) {
        CLLocationCoordinate2D coord = [v MKCoordinateValue];
        MKMapPoint point = MKMapPointForCoordinate(coord);
        MKMapRect pointRect = MKMapRectMake(point.x, point.y, factor, factor);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    
    return zoomRect;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (User *)me
{
    return [User me];
}

@end
