//
//  BaseFunctions.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#ifndef BaseFunctions_h
#define BaseFunctions_h


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
