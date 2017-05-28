//
//  UserProfile.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 25..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "UserProfile.h"
#import "PhotoView.h"
#import "MediaCollection.h"
#import "Compass.h"

@interface UserProfile ()
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nickname;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@property (weak, nonatomic) IBOutlet UILabel *gender;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *heading;
@property (weak, nonatomic) IBOutlet Compass *compass;
@property (weak, nonatomic) IBOutlet MediaCollection *mediaCollection;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeight;

@end

@implementation UserProfile

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nickname.text = self.user.nickname;
    self.introduction.text = self.user.channel;
    self.gender.text = self.user.genderTypeString;
    self.age.text = self.user.age;
    
    CGFloat distance = [[Engine where] distanceInKilometersTo:self.user.where];
    CGFloat heading = [[User where] headingToLocation:self.user.where];
    self.distance.text = __distanceString(distance);
    self.heading.text = __headingString(heading);
    self.compass.heading = heading;
    
    NSLog(@"Heading %f", heading);
    
    self.mediaCollection.parent = self;
    self.mediaCollection.user = self.user;
    self.photoView.media = self.user.media;
    // Do any additional setup after loading the view.
    
    self.bottomViewHeight.constant = self.user.photos.count ? 200.0f : 80.f;
    
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
