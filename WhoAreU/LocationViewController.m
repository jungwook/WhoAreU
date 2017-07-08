//
//  LocationViewController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LocationViewController.h"

@interface LocationCell : UICollectionViewCell
@property (weak, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
+ (id)identifier;
@end

@interface LocationViewController () <MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//@property (strong, nonatomic) MKMapCamera *camera;
@property (strong, nonatomic) NSArray <User*>*users;
@property (strong, nonatomic) NSMutableDictionary <id, LocationAnnotation*> *annotations;

@property (readonly, nonatomic) CGSize cellSize;
@property (weak, nonatomic) LocationAnnotation *highlightedAnnotation;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self setupCollectionView];
    [self setupMapViewAndCamera];
    [self loadUsers];
}

- (void)setupCollectionView
{
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[LocationCell class] forCellWithReuseIdentifier:LocationCell.identifier];
}

- (void)setupMapViewAndCamera
{
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(37.515791, 127.027807);
    self.mapView.pitchEnabled = YES;
    self.mapView.delegate = self;
    
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coords, 2000, 2000)];
//    self.camera = [MKMapCamera new];
//    self.camera.altitude = 200;
//    self.camera.pitch = 70.0f;
//    self.camera.heading = 0;
//    self.camera.centerCoordinate = coords;
//    self.mapView.camera = self.camera;
}

- (void)loadUsers
{
    self.annotations = [NSMutableDictionary new];
    PFQuery *query = [User query];
    [query setLimit:10];
    [query includeKey:fMedia];
    if ([User me]) {
        [query whereKey:fObjectId notEqualTo:[User me].objectId];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        self.users = objects;
        [self.users enumerateObjectsUsingBlock:^(User * _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
            LocationAnnotation *anno = [LocationAnnotation annotationWithUser:user];
            if (anno) {
                NSLog(@"USER:%@ (%.6f, %.6f)", anno.user.nickname, anno.coordinate.latitude, anno.coordinate.longitude);
                [self.mapView addAnnotation:anno];
                [self.annotations setObject:anno forKey:anno.user.objectId];
            }
        }];
        
        [self.collectionView reloadData];
        [self moveCameraToUser:self.users.firstObject];
    }];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    __LF
    self.highlightedAnnotation = view.annotation;
    [self.mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LocationAnnotationView *locationView = (id)view;
        NSUInteger index = [self.users indexOfObject:locationView.user];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    });
}

- (void)setHighlightedAnnotation:(LocationAnnotation *)highlightedAnnotation
{
    [self.mapView viewForAnnotation:self.highlightedAnnotation].highlighted = NO;
    _highlightedAnnotation = highlightedAnnotation;
    [self.mapView viewForAnnotation:self.highlightedAnnotation].highlighted = YES;
}

- (void)moveCameraToUser:(User*)user
{
    LocationAnnotation *anno = [self.annotations objectForKey:user.objectId];
    
    if (anno) {
        self.highlightedAnnotation = anno;
        [self.mapView setCenterCoordinate:anno.coordinate animated:YES];
    }
}

- (void)addUserLocation:(User*)user
{
    [self.mapView addAnnotation:[LocationAnnotation annotationWithUser:user]];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
        LocationAnnotationView* view = (LocationAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:LocationAnnotationView.identifier];
        
        if (!view) {
            view = [LocationAnnotationView viewWithAnnotation:annotation];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LocationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.user = [self.users objectAtIndex:indexPath.row];
    
    return cell;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 30, 10, 30);
}

- (CGSize)cellSize
{
    CGFloat w = CGRectGetWidth(self.collectionView.bounds), h = CGRectGetHeight(self.collectionView.bounds);

    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    CGFloat v = layout.sectionInset.bottom + layout.sectionInset.top;
    CGFloat height = h - v, width = w - 60;
    
    return CGSizeMake(width, height-20.f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10.0f;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    __LF
    CGFloat w = CGRectGetWidth(scrollView.bounds), h = CGRectGetHeight(scrollView.bounds);
    
    CGPoint point = scrollView.contentOffset;
    point.x += w/2.0f;
    point.y += h/2.0f;
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    User *user = [self.users objectAtIndexRow:indexPath];
    NSLog(@"Stopped at user:%@", user.nickname);
    [self moveCameraToUser:user];
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

@implementation LocationCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.shadowRadius = 5.0f;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:4.0f].CGPath;
}

- (void)setUser:(User *)user
{
    _user = user;
    [S3File getImageFromFile:self.user.thumbnail imageBlock:^(UIImage *image) {
        self.photoView.image = image ? image : [UIImage avatar];
    }];
    
    self.nickname.text = user.nickname;
}

+ (id)identifier
{
    return @"LocationCell";
}
@end
