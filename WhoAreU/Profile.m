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
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UILabel *sinceLabel;
@property (weak, nonatomic) IBOutlet ListField *age;
@property (weak, nonatomic) IBOutlet ListField *desc;
@property (weak, nonatomic) IBOutlet ListField *gender;
@property (weak, nonatomic) IBOutlet MediaCollection *mediaCollection;

@end

@implementation Profile

- (void)awakeFromNib
{
    [super awakeFromNib];
    __LF
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        __LF
    }
    return self;
}

- (void)setMe:(User *)me
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

    self.photoImageView.parent = self;
    self.nickname.delegate = self;
    self.mediaCollection.parent = self;

    self.me = [User me];
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
    __LF
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
    self.mediaCollection.user = self.me;
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

- (IBAction)editPhoto:(id)sender
{
    [self.photoImageView updateMedia];
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
            return [self headerViewWithTitle:@"Photos & Videos" action:@selector(addMoreMedia:)];
        }
            break;
            
        case 2: {
            return [self headerViewWithTitle:@"Credits" action:@selector(chargeCredits:)];
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
}

- (void) addMoreMedia:(id)sender
{
    [self.mediaCollection addMedia];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section>=1)
        return 50;
    else
        return 0;
}

- (UIView*) headerViewWithTitle:(NSString*)title action:(SEL)action
{
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = 50.0f, height = 22.0f, labelHeight = 30.0f;
    CGFloat o = 10.0f;
    UIView *v = [UIView new];
    UILabel *titleLabel = [UILabel new];
    titleLabel.frame = CGRectMake(o,
                                  h-labelHeight,
                                  w,
                                  labelHeight);
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    
    UIButton *addMoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [addMoreButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [addMoreButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    addMoreButton.frame = CGRectMake(w-o-height,
                                     h-height-o,
                                     height,
                                     height);
    addMoreButton.tintColor = [UIColor whiteColor];
    addMoreButton.backgroundColor = [UIColor blackColor];
    addMoreButton.radius = height/2.0f;
    
    [v addSubview:titleLabel];
    [v addSubview:addMoreButton];
    return v;
}


#pragma mark - Table view data source


@end
