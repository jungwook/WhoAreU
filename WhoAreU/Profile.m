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
#import "MediaCollection.h"

@interface Profile () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet PhotoView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UITextField *introduction;
@property (weak, nonatomic) IBOutlet UILabel *sinceLabel;
@property (weak, nonatomic) IBOutlet UILabel *credits;
@property (weak, nonatomic) IBOutlet ListField *age;
@property (weak, nonatomic) IBOutlet ListField *desc;
@property (weak, nonatomic) IBOutlet ListField *gender;
@property (weak, nonatomic) IBOutlet MediaCollection *mediaCollection;
@property (nonatomic) UIEdgeInsets contentInsets;
@end

@implementation Profile

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void) setup
{
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside:)]];
}

- (void) tappedOutside:(id)sender
{
    [self.view endEditing:YES];
}

- (void) setMe:(User *)me
{
    __LF
    _me = me;
    [self.me fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self setupUserDetails];
    }];
}

- (void)viewDidLoad
{
    __LF
    [super viewDidLoad];

    self.nickname.delegate = self;
    self.introduction.delegate = self;
    self.age.delegate = self;
    self.desc.delegate = self;
    self.gender.delegate = self;
    
    self.mediaCollection.parent = self;

    ANOTIF(kNotificationSystemInitialized, @selector(systemInitialzed:));
    ANOTIF(kNotificationEndEditing, @selector(notificationEndEditing:));
    ANOTIF(UIKeyboardWillShowNotification, @selector(keyboardWillShow:));
    ANOTIF(UIKeyboardWillHideNotification, @selector(keyboardWillHide:));
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    self.contentInsets = self.tableView.contentInset;
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    const CGFloat navigationBarHeight = 64.0f, tabBarHeight = 49.0f;
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(navigationBarHeight, 0, keyboardSize.height+tabBarHeight, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(navigationBarHeight, 0, keyboardSize.height+tabBarHeight, 0);
    }];
}

- (void)dealloc
{
    RANOTIF;
}

- (void)notificationEndEditing:(id)sender
{
    [self.tableView endEditing:YES];
}

- (void)systemInitialzed:(id)sender
{
    self.me = [User me];
}

- (IBAction)editingDidEnd:(id)sender {
    if (sender == self.nickname) {
        self.me.nickname = self.nickname.text;
        self.nicknameLabel.text = self.nickname.text;
    }
    else if (sender == self.introduction) {
        self.me.introduction = self.introduction.text;
    }
}

- (IBAction)saveUserDetails:(id)sender {
    [self.me saveInBackground];
}

- (void)setupUserDetails
{
    __LF
    [self.age setPickerForAgeGroupsWithHandler:^(id item) {
        self.me.age = item;
    }];
    [self.desc setPickerForIntroductionsWithHandler:^(id item) {
        self.me.channel = item;
    }];
    [self.gender setPickerForGendersWithHandler:^(id item) {
        [self.me setGenderTypeFromString:item];
    }];
    
    self.age.text = self.me.age;
    self.desc.text = self.me.channel;
    self.mediaCollection.user = self.me;
    self.gender.text = self.me.genderTypeString;
    self.nickname.text = self.me.nickname;
    self.introduction.text = self.me.introduction;
    self.nicknameLabel.text = self.me.nickname;
    self.username.text = self.me.username;
    self.sinceLabel.text = [NSString stringWithFormat:@"member since %@", [NSDateFormatter localizedStringFromDate:self.me.createdAt dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle]];
    self.credits.text = [@(self.me.credits).stringValue stringByAppendingString:@" Credits"];
    [self.photoImageView setMedia:self.me.media];
}

- (BOOL) photoExists
{
    return self.me.media;
}

- (IBAction)editPhoto:(id)sender
{
    [self.photoImageView updateMediaOnViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    __LF
    
    switch (section) {
        case 0:
            return nil;
            break;
            
        case 1: {
            return [self headerViewWithTitle:@"Profile" action:nil];
        }
            break;
            
        case 2: {
            return [self headerViewWithTitle:@"Photos & Videos" action:@selector(addMoreMedia:)];
        }
            break;
            
        case 3: {
            return [self headerViewWithTitle:@"Credits" action:@selector(chargeCredits:)];
        }
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section>=1)
        return 40;
    else
        return 0;
}

- (UIView*) headerViewWithTitle:(NSString*)title action:(SEL)action
{
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = 50.0f, size = 22.0f, labelHeight = 30.0f;
    CGFloat o = 10.0f;
    UIView *v = [UIView new];
    UILabel *titleLabel = [UILabel new];
    titleLabel.frame = CGRectMake(o,
                                  o,
                                  w,
                                  labelHeight);
    titleLabel.text = [title uppercaseString];
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    titleLabel.textColor = kAppColor;
    
    if (action) {
        UIButton *addMoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [addMoreButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
        [addMoreButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        addMoreButton.frame = CGRectMake(w-o-size,
                                         h-size-o,
                                         size,
                                         size);
        addMoreButton.tintColor = [UIColor whiteColor];
        addMoreButton.backgroundColor = kAppColor;
        addMoreButton.radius = size/2.0f;
        
        [v addSubview:addMoreButton];
    }
    [v addSubview:titleLabel];
    return v;
}


#pragma mark - Table view data source


@end
