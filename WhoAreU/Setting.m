//
//  Setting.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 5. 30..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "Setting.h"
#import "MediaCollection.h"
#import "SaveField.h"
#import "PhotoView.h"
#import "BlurView.h"
#import "Segment.h"
#import "TextField.h"

#define kSectionHeight 50

@interface Setting ()
@property (weak, nonatomic) IBOutlet PhotoView *photoView;
@property (weak, nonatomic) IBOutlet MediaCollection *mediaCollection;
@property (weak, nonatomic) IBOutlet SaveField *age;
@property (weak, nonatomic) IBOutlet SaveField *channel;
@property (weak, nonatomic) IBOutlet SaveField *nickname;
@property (weak, nonatomic) IBOutlet SaveField *introduction;
@property (weak, nonatomic) IBOutlet UILabel *credits;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *since;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gender;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet TextField *tf;
@end

@implementation Setting

- (void)viewDidAppear:(BOOL)animated
{
    __LF
}

- (void)viewDidDisappear:(BOOL)animated
{
    __LF
}

- (void)viewWillDisappear:(BOOL)animated
{
    __LF
}

- (void)viewWillAppear:(BOOL)animated
{
    __LF
    [super viewWillAppear:animated];
    
    [self updateUserDetails];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self notificationUserMediaUpdated:nil];
    });
    
//    self.tf.shouldValidateAction = ^BOOL(NSString *text) {
//        return [text canBeEmail];
//    };
//    
//    self.tf.validatedAction = ^BOOL(NSString *text) {
//        return [text isValidEmail];
//    };
    
    [self.tf setSelection:[User channels] default:[User channels].lastObject saveAction:^(NSString *string) {
        NSLog(@"SELECTED:%@", string);
    }];
    self.tf.optional = YES;
    self.tf.textColor = kAppColor;
    self.tf.pickerTextColor = [UIColor yellowColor];
    self.tf.pickerBackgroundColor = [UIColor femaleColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    
    self.mediaCollection.user = [User me];
    self.mediaCollection.parent = self;
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    [self.age setPickerItems:[User ageGroups] picked:^(NSUInteger index, id item) {
        NSLog(@"Selected:%@", item);
    } saved:^(NSString *string) {
        [User me].age = string;
        [[User me] saveInBackground];
    }];
    
    [self.channel setPickerItems:[User channels] picked:^(NSUInteger index, id item) {
        NSLog(@"Selected:%@", item);
    } saved:^(NSString *string) {
        [User me].channel = string;
        [[User me] saveInBackground];
    }];
    
    self.nickname.saveAction = ^(NSString *string){
        self.nicknameLabel.text = string;
        [User me].nickname = string;
        [[User me] saveInBackground];
    };
    self.introduction.saveAction = ^(NSString *string) {
        [User me].introduction = string;
        [[User me] saveInBackground];
    };
    
    [self updateUserDetails];
    
    Notification(UIKeyboardWillShowNotification, keyboardWillShow:);
    Notification(UIKeyboardWillHideNotification, keyboardWillHide:);
    Notification(kNotificationUserMediaUpdated, notificationUserMediaUpdated:);
}

- (void) notificationUserMediaUpdated:(NSNotification*)notification
{
    if ([User me].media == nil) {
        [self performSegueWithIdentifier:@"ProfilePhoto" sender:nil];
    }
}

- (void) updateUserDetails
{
    [[User me].media fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        id filename = [User me].media.type == kMediaTypePhoto ? [User me].media.media : [User me].media.thumbnail;
        
        [S3File getImageFromFile:filename imageBlock:^(UIImage *image) {
            [self.backgroundView drawImage:image];
        }];
    }];
    [self.photoView setMedia:[User me].media];
    self.nickname.text = [User me].nickname;
    self.age.text = [User me].age;
    self.channel.text = [User me].channel;
    self.introduction.text = [User me].introduction;
    self.credits.text = [NSString stringWithFormat:@"%ld credits", [User me].credits];
    self.gender.selectedSegmentIndex = [User me].gender;
    self.username.text = [User me].username;
    self.since.text = [NSString stringWithFormat:@"Joined since %@", [NSDateFormatter localizedStringFromDate:[User me].createdAt dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle]];
    self.nicknameLabel.text = [User me].nickname;
}

- (IBAction)genderSelected:(UISegmentedControl *)sender
{
    [User me].gender = sender.selectedSegmentIndex;
    [[User me] saveInBackground];
}

- (void)dealloc
{
    RemoveAllNotifications;
}

- (void) keyboardWillShow:(NSNotification*)notification
{
//    CGRect rect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    
//    CGFloat h = CGRectGetHeight(rect);
//    
//    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, h, 0);
}

- (void) keyboardWillHide:(id)sender
{
//    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
}

- (IBAction)tappedOutside:(id)sender {
    [self.tableView endEditing:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return nil;
            break;
            
        case 1: {
            NSString *profile = [[User me].nickname stringByAppendingString:@"'s Profile"];
            return [self headerViewWithTitle:profile
                                    subTitle:nil
                                      action:nil];
        }
            break;
            
        case 2: {
            return [self headerViewWithTitle:@"Credits"
                                    subTitle:@"add credits"
                                      action:@selector(chargeCredits:)];
        }
            break;
            
        case 3: {
            return [self headerViewWithTitle:@"Photos & Videos"
                                    subTitle:@"add media"
                                      action:@selector(addMoreMedia:)];
        }
            break;
            
        default:
            return nil;
            break;
    }
}

- (void) chargeCredits:(id)sender
{
    __LF
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Credits"];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void) addMoreMedia:(id)sender
{
    [self.mediaCollection addMedia];
}

- (IBAction)editMedia:(id)sender {
    [self.photoView updateMediaOnViewController:self
                                     completion:^(NSError *error)
    {
        if (!error) {
            [self updateUserDetails];
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section>=1)
        return kSectionHeight;
    else
        return 0;
}

- (UIView*) headerViewWithTitle:(NSString*)title
                       subTitle:(NSString*)subTitle
                         action:(SEL)action
{
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = kSectionHeight, size = 22.0f, labelHeight = kSectionHeight;
    CGFloat o = 10.0f;
    UIView *v = [UIView new];
    v.backgroundColor = [UIColor whiteColor];
    UILabel *subTitleLabel = [UILabel new];
    subTitleLabel.text = [subTitle uppercaseString];;
    subTitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    subTitleLabel.textColor = kAppColor;
    [subTitleLabel sizeToFit];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.frame = CGRectMake(o,
                                  (h-labelHeight)/2.0f,
                                  w,
                                  labelHeight);
    titleLabel.text = [title uppercaseString];
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    titleLabel.textColor = kAppColor;
    
    if (action) {
        UIButton *addMoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [addMoreButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
        [addMoreButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        addMoreButton.frame = CGRectMake(w-o-size,
                                         (h-size)/2.0f,
                                         size,
                                         size);
        addMoreButton.tintColor = [UIColor whiteColor];
        addMoreButton.backgroundColor = kAppColor;
        addMoreButton.radius = size/2.0f;

        CGFloat sw = CGRectGetWidth(subTitleLabel.bounds);
        
        subTitleLabel.frame = CGRectMake(w-o-size-o-sw, (h-size)/2.0f, sw, size);
        [v addSubview:subTitleLabel];
        [v addSubview:addMoreButton];
    }
    
    [v addSubview:titleLabel];
    return v;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ProfilePhoto"]) {
        
    }
}

@end
