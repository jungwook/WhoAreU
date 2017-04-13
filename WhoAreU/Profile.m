//
//  Profile.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 13..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Profile.h"
#import "PhotoView.h"
#import "ListField.h"
#import "MediaPicker.h"

@interface Profile () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet PhotoView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UILabel *sinceLabel;
@property (weak, nonatomic) IBOutlet ListField *age;
@property (weak, nonatomic) IBOutlet ListField *desc;
@property (weak, nonatomic) IBOutlet ListField *gender;
@property (weak, nonatomic) User *me;
@end

@implementation Profile

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.me = [User me];
    self.nickname.delegate = self;
    
    [self.me fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self setupUserDetails];
    }];
}

- (IBAction)updateUser:(id)sender {
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)editingDidEnd:(id)sender {
    self.me.nickname = self.nickname.text;
    self.nicknameLabel.text = self.nickname.text;
}

- (IBAction)saveUserDetails:(id)sender {
    [self.me saveInBackground];
}

- (void)setupUserDetails
{
    [self.age setPickerForAgeGroupsWithHandler:^(id item) {
        self.me.age = item;
    }];
    [self.desc setPickerForIntroductionsWithHandler:^(id item) {
        self.me.desc = item;
    }];
    [self.gender setPickerForGendersWithHandler:^(id item) {
        [self.me setGenderTypeFromString:item];
    }];
    
    self.age.text = self.me.age;
    self.desc.text = self.me.desc;
    self.gender.text = self.me.genderTypeString;
    self.nickname.text = self.me.nickname;
    self.nicknameLabel.text = self.me.nickname;
    self.sinceLabel.text = [NSString stringWithFormat:@"member since %@", [NSDateFormatter localizedStringFromDate:self.me.createdAt dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle]];
    
    [self.photoImageView setMedia:self.me.media];
}

- (BOOL) photoExists
{
    return self.me.media;
}

- (IBAction)editPhoto:(id)sender {
    void (^removeAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        self.me.media = nil;
        [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"User:%@", self.me);
        }];
        self.photoImageView.image = [UIImage imageNamed:@"avatar"];
    };
    void (^updateAction)(UIAlertAction * _Nonnull action) = ^(UIAlertAction * _Nonnull action){
        [MediaPicker pickMediaOnViewController:self withUserMediaHandler:^(Media *media, BOOL picked) {
            if (picked) {
                [self.photoImageView setMedia:media];
                self.me.media = media;
                [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    NSLog(@"User:%@", self.me);
                }];
            }
        }];
    };
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.photoExists) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Remove Photo"
                                                  style:UIAlertActionStyleDestructive
                                                handler:removeAction]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Update Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:updateAction]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
    }
    else {
        [alert addAction:[UIAlertAction actionWithTitle:@"Add Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:updateAction]];
    }
    
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
