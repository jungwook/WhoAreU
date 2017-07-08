//
//  SubProfile.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 22..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "SubProfile.h"
#import "TextField.h"
#import "MaterialDesignSymbol.h"

@interface SubProfile ()
@property (weak, nonatomic) IBOutlet TextField *username;
@property (weak, nonatomic) IBOutlet TextField *email;
@property (weak, nonatomic) IBOutlet TextField *age;
@property (weak, nonatomic) IBOutlet TextField *channel;
@property (weak, nonatomic) IBOutlet UIImageView *iconUsername;
@property (weak, nonatomic) IBOutlet UIImageView *iconEmail;
@property (weak, nonatomic) IBOutlet UIImageView *iconAge;
@property (weak, nonatomic) IBOutlet UIImageView *iconChannel;
@property (weak, nonatomic) IBOutlet UIImageView *iconGender;
@property (weak, nonatomic) IBOutlet UIImageView *iconIntro;
@property (weak, nonatomic) IBOutlet UIButton *iconMale;
@property (weak, nonatomic) IBOutlet UIButton *iconFemale;

@property (nonatomic) GenderType genderType;
@end

@implementation SubProfile

- (void)setIcon:(UIImageView*)imageView code:(NSString*)code
{
    imageView.image = [[[MaterialDesignSymbol iconWithCode:code fontSize:48] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imageView.tintColor = [UIColor blackColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.iconMale.tag = kGenderTypeMale;
    self.iconFemale.tag = kGenderTypeFemale;
 
    self.iconEmail.image = [UIImage materialDesign:MaterialDesignIconCode.email48px];
    self.iconUsername.image = [UIImage materialDesign:MaterialDesignIconCode.accountCircle48px];
    self.iconAge.image = [UIImage materialDesign:MaterialDesignIconCode.event48px];
    self.iconChannel.image = [UIImage materialDesign:MaterialDesignIconCode.folder48px];
    self.iconGender.image = [UIImage materialDesign:MaterialDesignIconCode.accountBox48px];
    self.iconIntro.image = [UIImage materialDesign: MaterialDesignIconCode.subject48px];
    
    self.genderType = kGenderTypeMale;
}

- (NSAttributedString*) attributedTitle:(NSString*)title
                                   font:(UIFont*)font
                                  color:(UIColor*)color
                               selected:(BOOL)selected
{
    id attr = @{
                NSFontAttributeName : font,
                NSForegroundColorAttributeName : color ? color : [UIColor clearColor],
                };
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:title attributes:attr];
    
    if (selected) {
        [attString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, title.length)];
    }
    return attString;
}


- (void)setGenderType:(GenderType)genderType
{
    _genderType = genderType;
    
    UIColor *color = genderType == kGenderTypeMale ? [UIColor maleColor] : (genderType == kGenderTypeFemale) ? [UIColor femaleColor] : [UIColor unknownGenderColor];
    UIColor *otherColor = genderType == kGenderTypeMale ? [UIColor femaleColor] : (genderType == kGenderTypeFemale) ? [UIColor maleColor] : [UIColor unknownGenderColor];
    
    otherColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0];
    UIColor *otherBackgroundColor = [UIColor colorWithWhite:0.8 alpha:0.4];
    
    UIButton *button = genderType == kGenderTypeMale ? self.iconMale : (genderType == kGenderTypeFemale) ? self.iconFemale : nil;
    UIButton *otherButton = button == self.iconMale ? self.iconFemale : self.iconMale;
    
    NSString *gender = [User genderTypeStringFromGender:genderType];
    NSString *otherGender = genderType == kGenderTypeMale ? [User genderTypeStringFromGender:kGenderTypeFemale] : [User genderTypeStringFromGender:kGenderTypeMale];
    
    NSAttributedString *title = [self attributedTitle:gender font:[UIFont systemFontOfSize:13 weight:UIFontWeightBold] color:[UIColor whiteColor] selected:NO];
    
    NSAttributedString *otherTitle = [self attributedTitle:otherGender font:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold] color:otherColor selected:NO];
    
    
    [UIView animateWithDuration:0.3 animations:^{
        [button setBackgroundColor:color];
        [button setAttributedTitle:title forState:UIControlStateNormal];
        [otherButton setBackgroundColor:otherBackgroundColor];
        [otherButton setAttributedTitle:otherTitle forState:UIControlStateNormal];
        
        [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            if (view.tag == 1199) {
                view.tintColor = color;
            }
        }];
    }];
}

- (IBAction)genderSelected:(UIButton*)sender
{
    self.genderType = sender.tag;
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
