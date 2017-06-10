//
//  UserMapCell.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 2..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import "UserMapCell.h"
#import "IndentedLabel.h"
#import "CompassView.h"
#import "MapView.h"

@interface UserMapCell()
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet MapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@end

@implementation UserMapCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setUser:(User *)user
{
    _user = user;
    [self.mapView setUser:self.user];
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        self.distance.text = [[User where] distanceStringToLocation:self.user.where];
        self.title.attributedText = self.locationString;
        [self.user.where reverseGeocode:^(NSString *string) {
            self.address.text = string;
        }];
    }];
}

- (void)setPhotoAction:(UserViewRectBlock)photoAction
{
    [self.mapView setPhotoAction:photoAction];
}

- (NSAttributedString*) locationString
{
    id attr1 = @{
                NSForegroundColorAttributeName : [UIColor blackColor],
                NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightBold],
                };
    id attr2 = @{
                NSForegroundColorAttributeName : [UIColor colorWithWhite:0.2 alpha:1.0],
                NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightMedium],
                };
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.user.nickname attributes:attr1];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"'s location" attributes:attr2]];
    
    return string;
}

@end
