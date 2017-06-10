//
//  ProfilePhoto.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 31..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "ProfilePhoto.h"
#import "PhotoView.h"
#import "MediaPicker.h"

@interface ProfilePhoto ()
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@property (readonly, nonatomic) User *me;
@end

@implementation ProfilePhoto

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (User *)me
{
    return [User me];
}

- (IBAction)fromLibrary:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary userMediaBlock:^(Media *media, BOOL picked) {
            if (picked) {
                self.photoView.media = media;
                self.me.media = media;
                [self.me saveInBackground];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }]
                           animated:YES
                         completion:nil];
    }
    else {
        __alert(@"WARNING", @"Library not available", nil, nil, self);
    }
}

- (IBAction)fromCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypeCamera userMediaBlock:^(Media *media, BOOL picked) {
            if (picked) {
                self.photoView.media = media;
                self.me.media = media;
                [self.me saveInBackground];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }]
                                 animated:YES
                               completion:nil];
    }
    else {
        __alert(@"WARNING", @"Camera not available", nil, nil, self);
    }
}

- (IBAction)skip:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
