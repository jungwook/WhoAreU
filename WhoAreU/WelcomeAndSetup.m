//
//  WelcomeAndSetup.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 3..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "WelcomeAndSetup.h"

@interface WelcomeAndSetup ()
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIScrollView *backgroundScrollView;
@property NSArray<UIView*> *subViews;
@end

@implementation WelcomeAndSetup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.subViews = @[
                      [[[NSBundle mainBundle] loadNibNamed:@"AddNicknameSubView" owner:self options:nil] firstObject],
                      [[[NSBundle mainBundle] loadNibNamed:@"AddMediaSubView" owner:self options:nil] firstObject],
                      [[[NSBundle mainBundle] loadNibNamed:@"AddAgeSubView" owner:self options:nil] firstObject],
                      [[[NSBundle mainBundle] loadNibNamed:@"AddIntroductionSubView" owner:self options:nil] firstObject],
                      [[[NSBundle mainBundle] loadNibNamed:@"AddAgeSubView" owner:self options:nil] firstObject],
                      ];
    
    NSLog(@"SubViews:%@", self.subViews);

    CGRect keyFrame = self.view.frame;
    CGFloat viewWidth = CGRectGetWidth(keyFrame);
    CGFloat viewHeight = CGRectGetHeight(keyFrame);

    self.backgroundScrollView = [[UIScrollView alloc] initWithFrame:keyFrame];
    self.backgroundScrollView.delegate = self;
    self.backgroundScrollView.pagingEnabled = YES;
    self.backgroundScrollView.userInteractionEnabled = NO;
    self.backgroundScrollView.contentSize = CGSizeMake(viewWidth+viewWidth*(self.subViews.count-1)*0.5f, viewHeight);
    self.backgroundScrollView.showsHorizontalScrollIndicator = NO;
    [self.backgroundScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    UIView *imageView = [UIView new];
    imageView.frame = CGRectMake(0, 0, viewWidth+viewWidth*(self.subViews.count-1)*0.5f, viewHeight);
    imageView.layer.contents = (id) [UIImage imageNamed:@"background"].CGImage;
    imageView.layer.contentsGravity = kCAGravityResizeAspectFill;
    [self.backgroundScrollView addSubview:imageView];

    [self.view addSubview:self.backgroundScrollView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:keyFrame];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(viewWidth * self.subViews.count, viewHeight);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    [self.view addSubview:self.scrollView];
    
    [self.subViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        view.frame = CGRectMake(idx*viewWidth, 0, viewWidth, viewHeight);
        [self.scrollView addSubview:view];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.backgroundScrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x * 0.5, 0) animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
