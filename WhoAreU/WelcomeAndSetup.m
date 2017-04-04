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
@property NSArray<WelcomeSubViewBase*> *subViews;
@end

@implementation WelcomeAndSetup

#define NIBVIEW(__X__) [[[NSBundle mainBundle] loadNibNamed:__X__ owner:self options:nil] firstObject]

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WelcomeSubViewBase *addNicknameSubView = NIBVIEW(@"AddNicknameSubView");
    WelcomeSubViewBase *addAgeSubView = NIBVIEW(@"AddAgeSubView");
    WelcomeSubViewBase *addIntroductionsSubView = NIBVIEW(@"AddIntroductionsSubView");
    WelcomeSubViewBase *addMediaSubView = NIBVIEW(@"AddMediaSubView");
    
    self.subViews = @[
                      addNicknameSubView,
                      addAgeSubView,
                      addIntroductionsSubView,
                      addMediaSubView,
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
    
    [self.subViews enumerateObjectsUsingBlock:^(WelcomeSubViewBase * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        view.frame = CGRectMake(idx*viewWidth, 0, viewWidth, viewHeight);
        [self.scrollView addSubview:view];
        view.prevBlock = ^(){
            [self scrollToPreviousPage];
        };
    }];
    
    addNicknameSubView.nextBlock = ^(NSString* nickname) {
        [self scrollToNextPage];
        NSLog(@"nickname is %@", nickname);
    };
    
    [[self.subViews firstObject] viewOnTop];
}

- (void) scrollToPreviousPage
{
    CGRect keyFrame = self.view.frame;
    CGFloat pageWidth = CGRectGetWidth(keyFrame);
    CGFloat pageFraction = self.scrollView.contentOffset.x / pageWidth;
    
    CGFloat nextPage = MAX(roundf(pageFraction)-1, 0);
    [self.scrollView setContentOffset:CGPointMake(pageWidth*nextPage, 0) animated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[self.subViews objectAtIndex:nextPage] viewOnTop];
    });
}

- (void) scrollToNextPage
{
    CGRect keyFrame = self.view.frame;
    CGFloat pageWidth = CGRectGetWidth(keyFrame);
    CGFloat pageFraction = self.scrollView.contentOffset.x / pageWidth;
    
    CGFloat nextPage = MIN(roundf(pageFraction)+1, self.subViews.count-1);
    [self.scrollView setContentOffset:CGPointMake(pageWidth*nextPage, 0) animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[self.subViews objectAtIndex:nextPage] viewOnTop];
    });
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
