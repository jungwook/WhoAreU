//
//  ProfileMain.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 18..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ProfileMain.h"
#import "PageTabs.h"
#import "TabBar.h"

@interface ProfileMain ()
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UIView *photoView;
@property (weak, nonatomic) IBOutlet TabBar *bar;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIView *pane;

@property (weak, nonatomic) UIPageViewController *pages;
@property (strong, nonatomic) NSArray<UIViewController*> *viewControllers;
@property (nonatomic, strong) NSArray<NSDictionary*>* items;
@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat inputYPosition;
@property (nonatomic) BOOL editing;
@property (nonatomic, readonly) CGPoint minCenterPoint, maxCenterPoint;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation ProfileMain

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.a
    self.items = @[
                      [self title:@"Profile" identifier:@"SubProfile"],
                      [self title:@"Location" identifier:@"SubLocation"],
                      [self title:@"Gallery" identifier:@"SubGallery"],
                      ];
    
    self.bar.selectAction = ^(NSUInteger index) {
        [self.view endEditing:YES];
        [self scrollToPage:index];
    };
    self.bar.index = 0;
    
    Notification(UIKeyboardWillShowNotification, keyboardWillShow:);
    Notification(UIKeyboardWillHideNotification, keyboardWillHide:);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)];
    tap.delegate = self;
    [self.container addGestureRecognizer:tap];
    [self.photoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)]];
    [self.pane addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)]];
    
    [self initCapture];
    self.bar.indicatorColor = [UIColor appColor];
    self.bar.selectedColor = [UIColor darkGrayColor];
    self.bar.deselectedColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.3];
}

- (void)scrollToPage:(NSUInteger)index
{
    UIPageViewControllerNavigationDirection direction = index > self.index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    self.index = index;
    [self.pages setViewControllers:@[self.viewControllers[index]] direction:direction animated:YES completion:nil];
}

- (void)panning:(UIPanGestureRecognizer*)gesture
{
    static const CGFloat threshold = 20.f, timeThreshold = 0.3f;
    static BOOL started = NO;
    static CGFloat startPos;
    static CGFloat prevMovement = 0.f;
    
    CGPoint translation = [gesture translationInView:self.view];
    CGFloat movement = translation.y, momentum = movement - prevMovement;
    
    static BOOL swipeup;
    static BOOL swipedown;
    
    static NSTimeInterval swipeTimestamp = 0;
    if (swipeup == NO && momentum<-threshold) {
        swipeup = YES;
        swipeTimestamp = [[NSDate date] timeIntervalSinceReferenceDate];
    }
    if (swipedown == NO && momentum>threshold) {
        swipedown = YES;
        swipeTimestamp = [[NSDate date] timeIntervalSinceReferenceDate];
    }
    
    if (swipedown || swipeup) {
        NSTimeInterval timeSinceLast = [[NSDate date] timeIntervalSinceReferenceDate] - swipeTimestamp;
        if (timeSinceLast > timeThreshold) {
            swipeup = NO;
            swipedown = NO;
            swipeTimestamp = 0;
        }
    }
    
    prevMovement = movement;

    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
            started = YES;
            swipeup = NO;
            swipedown = NO;
            startPos = self.pane.center.y;
            break;
        case UIGestureRecognizerStateChanged: {
            if (started == NO)
                return;
            
            self.pane.center = [self centerPointAt:startPos + movement cap:NO];
            
            swipeup = swipedown ? NO : swipeup;
            swipedown = swipeup ? NO : swipedown;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if (self.editing == NO) {
            }
            started = NO;
            [UIView animateWithDuration:0.25 animations:^{
                if (swipeup) {
                    self.pane.center = self.minCenterPoint;
                }
                else if (swipedown) {
                    self.pane.center = self.maxCenterPoint;
                }
                else {
                    self.pane.center = [self centerPointAt:startPos + movement cap:YES];
                }
            }];
            swipeup = NO;
            swipedown = NO;
            break;
        }
        default:
            break;
    }

}

- (CGPoint)centerPointAt:(CGFloat)offset cap:(BOOL)cap
{
    CGFloat min = CGRectGetHeight(self.pane.frame)/2.f+20.0f;
    CGFloat max = CGRectGetHeight(self.pane.frame)*3.f/2.f-110.f;
    
    if (cap) {
        offset = MAX(offset, min);
        offset = MIN(offset, max);
    }
    // Cap it to the status bar.
    offset = MAX(offset, min-20.f);
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.pane.frame), offset);
    
    return center;
}

- (CGPoint)minCenterPoint
{
    CGFloat min = CGRectGetHeight(self.pane.frame)/2.f + 20.f;
    CGPoint center = CGPointMake(CGRectGetMidX(self.pane.frame), min);
    
    return center;
}

- (CGPoint)maxCenterPoint
{
    CGFloat max = CGRectGetHeight(self.pane.frame)*3.f/2.f-110.f;
    CGPoint center = CGPointMake(CGRectGetMidX(self.pane.frame), max);
    return center;
}

- (void)tappedOutside:(id)sender {
    [self.view endEditing:YES];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL touchedEditView = [touch.view isKindOfClass:[UITextView class]];
    BOOL touchedTextField = [touch.view isKindOfClass:[UITextField class]];
    
    if (touchedTextField || touchedEditView) {
        self.inputYPosition = CGRectGetMaxY([self.view convertRect:touch.view.frame toView:self.view]);
    }
    return YES;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    self.editing = YES;
    CGFloat offset = 70.f, mid = self.view.center.y;

    CGRect rect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat move = mid + CGRectGetMinY(rect) - self.inputYPosition - offset;
    
    CGFloat duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.pane.center = [self centerPointAt:move cap:NO];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    self.editing = NO;
}

-(void)setItems:(NSArray *)items
{
    _items = items;
    
    self.bar.items = self.items;
    self.viewControllers = [self.items valueForKey:fViewController];
    
    if (self.items.count > 0) {
        [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
            [viewController view];
        }];
        [self scrollToPage:self.index];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Pages"]) {
        self.pages = segue.destinationViewController;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary*) title:(id)title identifier:(id)identifier
{
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    if (vc) {
        return @{
                 fTitle : title,
                 fViewController : vc,
                 };
    }
    else
        return nil;
}

- (void)viewDidLayoutSubviews
{
    self.pane.center = self.minCenterPoint;
    
    self.pane.shadowRadius = 10.f;
    self.pane.layer.shadowPath = [self.pane rountTopCornerPathWithRadius:8.0f].CGPath;
}

- (void)dealloc
{
    RemoveAllNotifications;
}

- (void)initCapture
{
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if (!captureInput) {
        return;
    }
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    /* captureOutput:didOutputSampleBuffer:fromConnection delegate method !*/
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    NSString* preset = 0;
    if (!preset) {
        preset = AVCaptureSessionPresetMedium;
    }
    self.captureSession.sessionPreset = preset;
    if ([self.captureSession canAddInput:captureInput]) {
        [self.captureSession addInput:captureInput];
    }
    if ([self.captureSession canAddOutput:captureOutput]) {
        [self.captureSession addOutput:captureOutput];
    }
    
    //handle prevLayer
    if (!self.previewLayer) {
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    
    //if you want to adjust the previewlayer frame, here!
    self.previewLayer.frame = self.photo.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.photo.layer insertSublayer:self.previewLayer atIndex:0];
    
    [self.captureSession startRunning];
}


@end
