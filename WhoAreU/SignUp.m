//
//  SignUp.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 22..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "SignUp.h"
#import "ListField.h"
#import "MediaPicker.h"
#import "PhotoView.h"

@interface SignUp ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *space;
@property (weak, nonatomic) IBOutlet UIView *pane;
@property (weak, nonatomic) IBOutlet UILabel *information;
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet ListField *withMe;
@property (weak, nonatomic) IBOutlet ListField *ageGroup;
@property (weak, nonatomic) IBOutlet ListField *gender;
@property (weak, nonatomic) IBOutlet PhotoView *photoImageView;

@property BOOL photoExists;
@property MediaType type;
@property SourceType source;
@property (strong, nonatomic) NSData *thumbnail;
@property (strong, nonatomic) NSData *photo;
@property (strong, nonatomic) NSData *movie;
@end

@implementation SignUp

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.photoExists = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.view setBackgroundColor:kAppColor];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.blurView setFrame:self.view.bounds];
    [self.blurView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.blurView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.view insertSubview:self.blurView atIndex:0];
    [self.ageGroup setPickerItems:[User ageGroups] withHandler:nil];
    [self.withMe setPickerItems:[User introductions] withHandler:^(id item) {
        
    }];
    [self.gender setPickerItems:[User genders] withHandler:^(id item) {
        self.information.text = @"Please make sure... You cannot change gender ever!";
    }];
    
    [self addObservers];
    self.space.constant = (self.view.bounds.size.height - self.pane.bounds.size.height) / 3.0f;
}

- (void)dealloc {
    [self removeObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nickname.delegate = self;
}

- (IBAction)editPhoto:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.photoExists) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Remove Photo"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            self.photoExists = NO;
            self.photo = nil;
            self.movie = nil;
            self.thumbnail = nil;
            self.photoImageView.image = [UIImage imageNamed:@"avatar"];
        }]];
    }
    else {
        [alert addAction:[UIAlertAction actionWithTitle:@"Add Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [MediaPicker pickMediaOnViewController:self withMediaHandler:^(MediaType mediaType, NSData *thumbnailData, NSData *originalData, NSData *movieData, SourceType source, BOOL picked) {
                self.photoExists = picked;
                if (picked) {
                    self.photoExists = YES;
                    self.type = mediaType;
                    self.thumbnail = thumbnailData;
                    self.photo = originalData;
                    self.movie = movieData;
                    self.source = source;
                    
                    self.photoImageView.image = [UIImage imageWithData:self.type == kMediaTypePhoto ? self.photo : self.thumbnail];
                }
            }];
        }]];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)proceed:(id)sender {
    BOOL notReady = NO;
    if ([self.nickname.text isEqualToString:kStringNull]) {
        self.information.text = @"You must enter a unique nickname!";
        notReady = YES;
    }
    else if ([self.withMe.text isEqualToString:kStringNull]) {
        self.information.text = @"Please select why you're here!";
        notReady = YES;
    }
    else if ([self.ageGroup.text isEqualToString:kStringNull]) {
        self.information.text = @"Please select an age group";
        notReady = YES;
    }
    else if ([self.gender.text isEqualToString:kStringNull]) {
        self.information.text = @"Please select your gender. You cannot change this ever!";
        notReady = YES;
    }
    
    if (!notReady && self.completionBlock) {
        self.completionBlock(self,
                             self.nickname.text,
                             self.withMe.text,
                             self.ageGroup.text,
                             self.gender.text,
                             self.photoExists,
                             self.type,
                             self.thumbnail,
                             self.photo,
                             self.movie,
                             self.source);
        self.information.text = @"Processing...";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.nickname.text isEqualToString:kStringNull]) {
            self.nickname.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        }
        else {
            self.nickname.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
        }
    });
    return YES;
}

- (void)setInfo:(NSString *)info
{
    self.information.text = info;
}

- (void) addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doKeyBoardEvent:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
}

- (void) removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
}

- (IBAction)tappedOutside:(id)sender {
    [self.view endEditing:YES];
}

- (void)doKeyBoardEvent:(NSNotification *)notification
{
    static CGRect keyboardEndFrameWindow;
    static double keyboardTransitionDuration;
    static UIViewAnimationCurve keyboardTransitionAnimationCurve;
    
    if (notification) {
        [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardEndFrameWindow];
        [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&keyboardTransitionDuration];
        [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&keyboardTransitionAnimationCurve];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.space.constant = (keyboardEndFrameWindow.origin.y - self.pane.bounds.size.height) / 3.0f;
        [self.pane setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:keyboardTransitionDuration delay:0.0f options:(keyboardTransitionAnimationCurve << 16) animations:^{
            [self.pane layoutIfNeeded];
        } completion:nil];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
