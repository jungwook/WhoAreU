//
//  Preview.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 2..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "Preview.h"

@interface CenterScrollView : UIScrollView
@end

@implementation CenterScrollView

-(void)layoutSubviews
{
    [super layoutSubviews];
    UIView* v = [self.delegate viewForZoomingInScrollView:self];
    CGFloat svw = self.bounds.size.width;
    CGFloat svh = self.bounds.size.height;
    CGFloat vw = v.frame.size.width;
    CGFloat vh = v.frame.size.height;
    CGFloat off = 64.0f;
    CGRect f = v.frame;
    
    off = 0.0f;
    
    if (vw < svw)
        f.origin.x = (svw - vw) / 2.0;
    else
        f.origin.x = 0;
    
    if (vh < svh)
        f.origin.y = (svh - vh) / 2.0 - off;
    else
        f.origin.y = -off;
    v.frame = f;
}

@end

@interface Preview () <UIScrollViewDelegate>
@property (strong, nonatomic) CenterScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic) CGFloat zoom;
@end

@implementation Preview

- (instancetype)initWithImage:(UIImage*)image
{
    self = [super init];
    if (self) {
        self.scrollView = [[CenterScrollView alloc] initWithFrame:self.view.frame];
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.scrollView];

        self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.imageView.backgroundColor = [UIColor redColor];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:self.imageView];

        NSDictionary *metrics = @{@"height" : @(image.size.height), @"width" : @(image.size.width)};
        NSDictionary *views = @{@"imageView":self.imageView};
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(height)]|" options:kNilOptions metrics:metrics views:views]];
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(width)]|" options:kNilOptions metrics:metrics views:views]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;

        self.imageView.image = image;
        
        // Tap gesture recognizers
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        
        [self.scrollView addGestureRecognizer:doubleTap];
        [self.scrollView addGestureRecognizer:singleTap];
        
        // initialize zoom factors for image
        
        [self initZoomWithImage:image];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) singleTap:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) doubleTap:(id)sender {
    static CGFloat prev = 1;
    
    CGFloat zoom = self.scrollView.zoomScale;
    [UIView animateWithDuration:0.1 animations:^{
        self.scrollView.zoomScale = prev;
    }];
    prev = zoom;
}

- (void) initZoomWithImage:(UIImage*)image
{
    float minZoom = MIN(self.view.bounds.size.width / image.size.width, self.view.bounds.size.height / image.size.height);
    if (minZoom > 1) return;
    
    self.scrollView.minimumZoomScale = minZoom;
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.zoomScale = minZoom;
    self.zoom = minZoom;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.zoom = scale;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
