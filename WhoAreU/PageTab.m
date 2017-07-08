//
//  PageTab.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PageTab.h"
#import "TabBar.h"
#import "MessageCenter.h"

@interface PageTab () <UITabBarDelegate>
@property (weak, nonatomic) IBOutlet TabBar *tabs;
@property (weak, nonatomic) UIPageViewController *pages;
@property (strong, nonatomic) NSArray<UIViewController*> *viewControllers;
@property (strong, nonatomic) NSArray<NSDictionary*> *tabItems;
@property (nonatomic) NSUInteger index;
@end

@implementation PageTab

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#define VC(__I__) [self.storyboard instantiateViewControllerWithIdentifier:__I__]

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tabs.equalWidth = NO;
    self.tabItems = @[
                      @{
                          fTitle : @"Location",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Location"),
                          fNavigationControllerRequired : @(YES),
                          },
                      @{
                          fTitle : @"Users",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Cards"),
                          },
                      @{
//                          fTitle : @"Users",
                          fIcon : @"pin",
                          fDeselectedIcon : @"pin",
                          fViewController : VC(@"Users"),
                          },
                      @{
//                          fTitle : @"Me",
                          fIcon : @"user",
                          fDeselectedIcon : @"user",
                          fViewController : VC(@"ProfileMain"),
                          },
                      @{
//                          fTitle : @"Me",
                          fIcon : @"heart",
                          fDeselectedIcon : @"heart",
                          fViewController : VC(@"UserProfile"),
                         },
                      @{
//                          fTitle : @"Chat",
                          fIcon : @"message2",
                          fDeselectedIcon : @"message2",
                          fViewController : VC(@"Chats"),
                          },
                      @{
//                          fTitle : @"Channel",
                          fIcon : @"pin2",
                          fDeselectedIcon : @"pin2",
                          fViewController : VC(@"Channels"),
                          },
                ];
    
    
    self.tabs.position = kTabBarIndicatorPositionTop;
    self.tabs.selectAction = ^(NSUInteger index) {
        UIPageViewControllerNavigationDirection direction = index > self.index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        self.index = index;
        [self.pages setViewControllers:@[self.viewControllers[index]] direction:direction animated:YES completion:nil];
    };
    
    self.tabs.backgroundColor = [UIColor whiteColor];
    self.tabs.blurOn = YES;
    self.tabs.selectedColor = [UIColor appColor];
    self.tabs.deselectedColor = [[UIColor appColor] colorWithAlphaComponent:0.4];
    self.tabs.indicatorColor = [UIColor appColor];
    
//    self.tabs.selectedColor = [UIColor whiteColor];
//    self.tabs.deselectedColor = [UIColor colorWithWhite:0.9 alpha:0.4];
//    self.tabs.indicatorColor = [UIColor whiteColor];
//    self.tabs.backgroundColor = [UIColor appColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MessageCenter startFromViewController:self];
}

-(void)setTabItems:(NSArray *)tabItems
{
    NSMutableArray *viewControllers = [NSMutableArray new];
    _tabItems = tabItems;
    
    self.tabs.items = self.tabItems;
    
    [self.tabItems enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull tabItem, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController* vc = [tabItem objectForKey:fViewController];
        id ncr = [tabItem objectForKey:fNavigationControllerRequired];
        if (ncr && ![vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
            [viewControllers addObject:nc];
        }
        else {
            [viewControllers addObject:vc];
        }
    }];
    
//    self.viewControllers = [self.tabItems valueForKey:fViewController];
    
    self.viewControllers = viewControllers;
    [self.pages setViewControllers:@[self.viewControllers.firstObject] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    __LF
    if ([segue.identifier isEqualToString:@"Pages"]) {
        self.pages = segue.destinationViewController;
    }
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
