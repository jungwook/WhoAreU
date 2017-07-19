//
//  MainMenuViewController.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 7. 19..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "MainMenuViewController.h"

@interface MainMenuViewController ()
@property (nonatomic, strong) NSArray <UIViewController*> *viewControllers;
@end


@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIViewController *vc1 = [UIViewController new];
    vc1.view.backgroundColor = [UIColor redColor];
    UIViewController *vc2 = [UIViewController new];
    vc2.view.backgroundColor = [UIColor yellowColor];
    UIViewController *vc3 = [UIViewController new];
    vc3.view.backgroundColor = [UIColor blueColor];
    
    self.viewControllers = @[ vc1, vc2, vc3];
    
    [self showViewController:self.viewControllers.firstObject sender:self];
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
