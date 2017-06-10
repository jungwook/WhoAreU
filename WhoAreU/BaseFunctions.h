//
//  BaseFunctions.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#ifndef BaseFunctions_h
#define BaseFunctions_h

#import "User.h"

CALayer*    __drawImageOnLayer(UIImage *image, CGSize size);
UIImage*    __scaleImage(UIImage* image, CGSize size);
void        __drawImage(UIImage *image, UIView* view);
void        __circleizeView(UIView* view, CGFloat percent);
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

NSString*   __dateString(NSDate* date);

void        __alert(NSString* title, NSString* message, AlertAction okAction, AlertAction cancelAction, UIViewController* parent);
id          __dictionary(id object);

@interface UIColor (extensions)
- (NSString*)stringValue;
+ (UIColor*) colorFromString:(NSString*)colorString;
+ (UIColor*) appColor;
+ (UIColor*) maleColor;
+ (UIColor*) femaleColor;
+ (UIColor*) unknownGenderColor;
- (UIColor*) grayscale;
+ (UIColor*) interpolateHSVColorFrom:(UIColor *)start to:(UIColor *)end withFraction:(float)f;
+ (UIColor*) interpolateRGBColorFrom:(UIColor *)start to:(UIColor *)end withFraction:(float)f;
- (UIColor*) lighterColor;
- (UIColor*) darkerColor;

@end

@interface PFGeoPoint (extensions)
- (CLLocationDegrees) headingToLocation:(PFGeoPoint*)location;
- (NSString*) distanceStringToLocation:(PFGeoPoint *)location;
- (CGFloat) headingInRadiansToLocation:(PFGeoPoint*)location;
+ (instancetype) geoPointFromWhere:(id)where;
- (void) reverseGeocode:(StringBlock)handler;
@end

@interface NSDate (extensions)
- (NSDate *)    dateWithoutTime;
- (NSString*)   stringUTC;
+ (NSDate*)     dateFromStringUTC:(NSString*)string;
@end

@interface User (extensions)
- (CLLocationDegrees) headingToUser:(User*)user;

@end

@interface PFConfig (extensions)
+ (id) objectForLocaleKey:(id)key;
@end

@interface NSString (extensions)
- (CGRect)  boundingRectWithFont:(UIFont*)font maxWidth:(CGFloat) width;
- (CGFloat) heightWithFont:(UIFont*)font maxWidth:(CGFloat)width;
- (BOOL)    isValidEmail;
- (NSString*) substringWithNumberOfWords:(NSUInteger)count;
- (UIColor*) UIColor;
@end

@interface UIView (extensions)
- (void) drawImage:(UIImage*)image;
@end

@interface UIImage (extensions)
+ (UIImage*) avatar;
@end
#endif /* BaseFunctions_h */
