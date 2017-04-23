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


#define POINT_FROM_CLLOCATION(__X__) [PFGeoPoint geoPointWithLocation:__X__]
#define POINT_FROM_COORDINATES(__X__) [PFGeoPoint geoPointWithLatitude:__X__.latitude longitude:__X__.longitude]
#define SIMULATOR_LOCATION [PFGeoPoint geoPointWithLatitude:37.515791f longitude:127.027807f]

#define kAppColor [UIColor colorWithRed:95/255.f green:167/255.f blue:229/255.f alpha:1.0f]
#define appScreen [UIScreen mainScreen]
#define appWindow [UIApplication sharedApplication].keyWindow


CALayer*    drawImageOnLayer(UIImage *image, CGSize size);
UIImage*    scaleImage(UIImage* image, CGSize size);
void        drawImage(UIImage *image, UIView* view);
void        circleizeView(UIView* view, CGFloat percent);
void        roundCorner(UIView* view);
float       heading(PFGeoPoint* fromLoc, PFGeoPoint* toLoc);
float       headingRadians(PFGeoPoint* fromLoc, PFGeoPoint* toLoc);
float       Heading(PFUser* from, PFUser* to);
CGRect      hiveToFrame(CGPoint hive, CGFloat radius, CGFloat inset, CGPoint center);
CGRect      rectForString(NSString *string, UIFont *font, CGFloat maxWidth);
NSData*     compressedImageData(NSData* data, CGFloat width);
NSString*   randomObjectId();
NSString*   distanceString(double distance);
CGFloat     ampAtIndex(NSUInteger index, NSData* data);
void        setShadowOnView(UIView* view, CGFloat radius, CGFloat opacity);
CGFloat     widthForNumberOfCells(UICollectionView* cv, UICollectionViewFlowLayout *flowLayout, CGFloat cpr);
UIView*     viewWithTag(UIView *view, NSInteger tag);
PFGeoPoint* pointFromCLLocation(CLLocation* location);
PFGeoPoint* pointFromCoordinates(CLLocationCoordinate2D  coordinates);


#endif /* BaseFunctions_h */
