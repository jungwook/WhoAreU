//
//  BaseFunctions.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#ifndef BaseFunctions_h
#define BaseFunctions_h

#define __LF NSLog(@"%s", __FUNCTION__);

#define kJPEGCompressionLow 0.2f
#define kJPEGCompressionMedium 0.4f
#define kJPEGCompressionDefault 0.6f
#define kJPEGCompressionFull 1.0f
#define kThumbnailWidth 100
#define kVideoThumbnailWidth 320
#define S3LOCATION @"http://whoareu.s3.ap-northeast-2.amazonaws.com/"

#define ANOTIF(__X__,__Y__) [[NSNotificationCenter defaultCenter] addObserver:self selector:__Y__ name:__X__ object:nil]

#define RNOTIF(__Y__) [[NSNotificationCenter defaultCenter] removeObserver:self name:__Y__ object:nil]

#define RANOTIF [[NSNotificationCenter defaultCenter] removeObserver:self]

#define POINT_FROM_CLLOCATION(__X__) [PFGeoPoint geoPointWithLocation:__X__]
#define POINT_FROM_COORDINATES(__X__) [PFGeoPoint geoPointWithLatitude:__X__.latitude longitude:__X__.longitude]
#define SIMULATOR_LOCATION [PFGeoPoint geoPointWithLatitude:37.515791f longitude:127.027807f]

#define kAppColor [UIColor colorWithRed:95/255.f green:167/255.f blue:229/255.f alpha:1.0f]
#define appScreen [UIScreen mainScreen]
#define appWindow [UIApplication sharedApplication].keyWindow
#define mainWindow [[[UIApplication sharedApplication] delegate] window]

typedef void(^AlertAction)(UIAlertAction *action);

CALayer*    __drawImageOnLayer(UIImage *image, CGSize size);
UIImage*    __scaleImage(UIImage* image, CGSize size);
void        __drawImage(UIImage *image, UIView* view);
void        __circleizeView(UIView* view, CGFloat percent);
float       __heading(PFGeoPoint* fromLoc, PFGeoPoint* toLoc);
float       __headingRad(PFGeoPoint* fromLoc, PFGeoPoint* toLoc);
float       __headingUsers(PFUser* from, PFUser* to);
CGRect      __rectForString(NSString *string, UIFont *font, CGFloat maxWidth);
NSData*     __compressedImageData(NSData* data, CGFloat width);
NSData*     __compressedImageDataQuality(NSData* data, CGFloat width, CGFloat compressionRatio);
NSString*   __randomObjectId();
NSString*   __distanceString(double distance);
NSString*   __headingString(double heading);
CGFloat     __ampAtIndex(NSUInteger index, NSData* data);
void        __setShadowOnView(UIView* view, CGFloat radius, CGFloat opacity);
CGFloat     __widthForNumberOfCells(UICollectionView* cv, UICollectionViewFlowLayout *flowLayout, CGFloat cpr);
UIView*     __viewWithTag(UIView *view, NSInteger tag);
PFGeoPoint* __pointFromCLLocation(CLLocation* location);
PFGeoPoint* __pointFromCoordinates(CLLocationCoordinate2D  coordinates);

void        __alert(UIViewController* parent, NSString* title, NSString* message, AlertAction okAction, AlertAction cancelAction);
id          __dictionary(id object);

NSString *NSStringFromUIColor(UIColor *color);
UIColor *UIColorFromNSString(NSString *string);

#endif /* BaseFunctions_h */
