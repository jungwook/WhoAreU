//
//  Card.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 6. 29..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTabBarPageCount 3

enum {
    eSectionProfile = 0,
    eSectionLocation,
    eSectionGallery
};

#define kMaskViewRadius 0.f
#define kCardInset 8.f
#define kCardBarHeight 44.f
#define kCardTopBottomInsets 2*kCardInset
#define kCardSideInsets 2*kCardInset
#define kCardCameraIcon [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.cameraAlt48px fontSize:48]
#define kCardPhotoIcon [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.photo48px fontSize:48]

#define kCardPlayIcon [MaterialDesignSymbol iconWithCode:MaterialDesignIconCode.playCircleFill48px fontSize:48]

#define TemplateImage(__X__) [[__X__ image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]


typedef const struct {
    __unsafe_unretained id sectionProfile;
    __unsafe_unretained id sectionLocation;
    __unsafe_unretained id sectionGallery;
} TabBarSections;


@interface Card : UICollectionViewCell
@property (copy, nonatomic) VoidBlock likeAction, chatAction;
@property (nonatomic, readonly) UIFont *titleFont, *subTitleFont, *presentationFont, *statusFont;
@property (nonatomic, weak) User *user;
- (void) playVideoIfVideo;
@end

