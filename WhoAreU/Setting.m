//
//  Setting.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Setting.h"
#import "S3File.h"

@interface Setting ()
@property (weak, nonatomic) IBOutlet UIView *imageView;

@end

@implementation Setting

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOffset = CGSizeZero;
    self.imageView.layer.shadowRadius = 4.0f;
    self.imageView.layer.shadowOpacity = 0.6f;
    self.imageView.clipsToBounds = NO;
    
    Media *media = [User me].media;
    [media fetched:^{
        [S3File getImageFromFile:media.media imageBlock:^(UIImage *image) {
            __drawImage(image, self.imageView);
        }];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section==0)
        return 0;
    else
        return 20;
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
