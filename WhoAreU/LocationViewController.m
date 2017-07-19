//
//  LocationViewController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 5..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "LocationViewController.h"
#import "BlurView.h"

@interface LocationCell : UICollectionViewCell
@property (weak, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
+ (id)identifier;
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
        dispatch_foreground(^{
            self.photoView.image = image ? image : [UIImage avatar];
        });
    }];
    
    self.nickname.text = user.nickname;
}

+ (id)identifier
{
    return @"LocationCell";
}
@end

@interface LocationViewController () <MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet BlurView *blur;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//@property (strong, nonatomic) MKMapCamera *camera;
@property (strong, nonatomic) NSArray <User*>*users;
@property (strong, nonatomic) NSMutableDictionary <id, LocationAnnotation*> *annotations;

@property (readonly, nonatomic) User* selectedUser;
@property (readonly, nonatomic) CGSize cellSize;
@property (readonly, nonatomic) LocationAnnotationView* selectedAnnotationView;
@property (weak, nonatomic) LocationAnnotation *selectedAnnotation;

@property (readonly, nonatomic) UIEdgeInsets sectionInset;
@end

@implementation LocationViewController

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
    self.blur.alpha = 0;
    
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
    self.mapView.showsUserLocation = NO;
    
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coords, 2000, 2000)];
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
            LocationAnnotation *annotation = [LocationAnnotation annotationWithMap:self.mapView andUser:user];
            if (annotation) {
                [self.mapView addAnnotation:annotation];
                [self.annotations setObject:annotation forKey:annotation.user.objectId];
            }
            else {
                NSLog(@"Cannot create annotation for user:%@", user.nickname);
            }
        }];
        [self.collectionView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self centerMapToUser:self.users.firstObject];
        });
    }];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self showAnnotations:YES];
    
}

- (LocationAnnotationView *)selectedAnnotationView
{
    return (id) [self.mapView viewForAnnotation:self.selectedAnnotation];
}

- (void)tappedAnnotation:(UITapGestureRecognizer*)tap
{
    if ([tap.view isKindOfClass:[LocationAnnotationView class]]) {
        LocationAnnotationView *view = (id) tap.view;
        NSLog(@"Tapped user:%@", view.locationAnnotation.user.nickname);
        [self scrollToUser:view.locationAnnotation.user];
        self.selectedAnnotation = view.annotation;
    }
    else {
        NSLog(@"Tapped something else");
    }
}

- (void)scrollToUser:(User*)user
{
    NSLog(@"Scrolling to user:%@", user.nickname);
    NSUInteger index = [self.users indexOfObject:user];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)setSelectedAnnotation:(LocationAnnotation *)selectedAnnotation
{
    NSLog(@"Selecting annotation for user:%@", selectedAnnotation.user.nickname);
    self.selectedAnnotation.highlighted = NO;
    _selectedAnnotation = selectedAnnotation;
    self.selectedAnnotation.highlighted = YES;
}

- (void)centerMapToUser:(User*)user
{
    LocationAnnotation *annotation = [self.annotations objectForKey:user.objectId];
    
    if (annotation) {
        self.selectedAnnotation = annotation;
        
        dispatch_foreground(^{
//            const CGFloat statusBarOffset = 64.f;
//            CGRect frame = self.collectionView.frame;
//            CGFloat y = CGRectGetMinY(frame)-statusBarOffset;
//            
//            CGPoint point = [self.mapView convertCoordinate:annotation.coordinate toPointToView:self.mapView];
//            point.y += y/2.f;
//            
//            CLLocationCoordinate2D center = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];

            [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
//            [self.mapView setCenterCoordinate:center animated:YES];
        });
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
        LocationAnnotationView* view = (LocationAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:LocationAnnotationView.identifier];
        
        if (!view) {
            view = [LocationAnnotationView viewWithAnnotation:annotation];
            [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAnnotation:)]];
        }
        else {
            view.annotation = annotation;
        }
        return view;
    }
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView
                         layout:(UICollectionViewLayout *)collectionViewLayout
         insetForSectionAtIndex:(NSInteger)section
{
    return self.sectionInset;
}

- (UIEdgeInsets)sectionInset
{
    return UIEdgeInsetsMake(10, 80, 10, 80);
}

- (CGSize)cellSize
{
    CGFloat w = CGRectGetWidth(self.collectionView.bounds), h = CGRectGetHeight(self.collectionView.bounds);

    CGFloat tb = self.sectionInset.bottom + self.sectionInset.top;
    CGFloat lr = self.sectionInset.left + self.sectionInset.right;
    
    CGFloat height = h - tb, width = w - lr;
    
    return CGSizeMake(width, height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.f;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat w = CGRectGetWidth(scrollView.bounds), h = CGRectGetHeight(scrollView.bounds);
    CGPoint point = CGPointMake((*targetContentOffset).x + w/2.f, (*targetContentOffset).y + h/2.f);
    dispatch_foreground(^{
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        User *user = [self.users objectAtIndexRow:indexPath];
        [self centerMapToUser:user];
    });
}

- (User*)selectedUser
{
    CGFloat w = CGRectGetWidth(self.collectionView.bounds), h = CGRectGetHeight(self.collectionView.bounds);
    CGPoint targetContentOffset = self.collectionView.contentOffset;
    CGPoint point = CGPointMake(targetContentOffset.x + w/2.f, targetContentOffset.y + h/2.f);
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    return [self.users objectAtIndexRow:indexPath];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self showAnnotations:NO];
}

- (void) showAnnotations:(BOOL)show
{
    [self.annotations enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, LocationAnnotation * _Nonnull annotation, BOOL * _Nonnull stop) {
        UIView *view = [self.mapView viewForAnnotation:annotation];
        [self showView:view show:show];
    }];
}

- (void)showView:(UIView*)view show:(BOOL)show
{
    [UIView animateWithDuration:0.35f animations:^{
        view.alpha = show;
    }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
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

