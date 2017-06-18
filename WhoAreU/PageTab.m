//
//  PageTab.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 15..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "PageTab.h"
#import "PageTabs.h"

@interface PageTab () <UITabBarDelegate>
@property (weak, nonatomic) IBOutlet PageTabs *tabs;
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

- (void)viewDidLoad
{
    __LF
    [super viewDidLoad];
    self.tabs.selectedColor = [UIColor groupTableViewBackgroundColor];
    self.tabs.defaultColor = [UIColor lightGrayColor];
    self.tabItems = @[
                      [self title:@"Me" icon:@"pin2" identifier:@"ProfileMain"],
                      [self title:@"Me" icon:@"pin2" identifier:@"UserProfile"],
                      [self title:@"Users" icon:@"pin2" identifier:@"Users"],
                      [self title:@"Chat" icon:@"pin2" identifier:@"Chats"],
                      [self title:@"Channel" icon:@"pin2" identifier:@"Channels"],
                ];
    self.tabs.selectAction = ^(NSUInteger index) {
        UIPageViewControllerNavigationDirection direction = index > self.index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        self.index = index;
        [self.pages setViewControllers:@[self.viewControllers[index]] direction:direction animated:YES completion:nil];
    };
}

- (NSDictionary*) title:(id)title icon:(id)icon identifier:(id)identifier
{
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    if (vc) {
        return @{
                 fTitle : title,
//                 fIcon : icon,
                 fViewController : vc,
                 };
    }
    else
        return nil;
}


-(void)setTabItems:(NSArray *)tabItems
{
    _tabItems = tabItems;
    
    self.tabs.items = self.tabItems;
    self.viewControllers = [self.tabItems valueForKey:fViewController];
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
