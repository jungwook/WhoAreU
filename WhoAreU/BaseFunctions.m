//
//  BaseFunctions.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseFunctions.h"

CALayer* __drawImageOnLayer(UIImage *image, CGSize size)
{
    CALayer *layer = [CALayer layer];
    [layer setBounds:CGRectMake(0, 0, size.width, size.height)];
    [layer setContents:(id)image.CGImage];
    [layer setContentsGravity:kCAGravityResizeAspect];
    [layer setMasksToBounds:YES];
    return layer;
}

UIImage* __scaleImage(UIImage* image, CGSize size) {
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
    [__drawImageOnLayer(image,size) renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return smallImage;
}

NSString* __dateString(NSDate* date)
{
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    return [formatter stringFromDate:date];
}

void __drawImage(UIImage *image, UIView* view)
{
    [view.layer setContents:(id)image.CGImage];
    [view.layer setContentsGravity:kCAGravityResizeAspectFill];
    [view.layer setMasksToBounds:YES];
}

void __circleizeView(UIView* view, CGFloat percent)
{
    view.layer.cornerRadius = view.frame.size.height * percent;
    view.layer.masksToBounds = YES;
}

NSData* __compressedImageDataQuality(NSData* data, CGFloat width, CGFloat compressionRatio)
{
    UIImage *image = [UIImage imageWithData:data];
    const CGFloat thumbnailWidth = width;
    CGFloat thumbnailHeight = image.size.width ? thumbnailWidth * image.size.height / image.size.width : 200;
    image = __scaleImage(image, CGSizeMake(thumbnailWidth, thumbnailHeight));
    return UIImageJPEGRepresentation(image, compressionRatio);
}

NSData* __compressedImageData(NSData* data, CGFloat width)
{
    return __compressedImageDataQuality(data, width, kJPEGCompressionMedium);
}

CGRect __rectForString(NSString *string, UIFont *font, CGFloat maxWidth)
{
    CGRect rect = CGRectIntegral([string boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{
                                                                NSFontAttributeName: font,
                                                                } context:nil]);
    return rect;
}



NSString* __randomObjectId()
{
    int length = 8;
    char *base62chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    
    NSString *code = kStringNull;
    
    for (int i=0; i<length; i++) {
        int rand = arc4random_uniform(36);
        code = [code stringByAppendingString:[NSString stringWithFormat:@"%c", base62chars[rand]]];
    }
    
    return code;
}

NSString* __headingString(double heading)
{
    if (heading >= -22.5 && heading < 22.5) {
        return @"N";
    }
    else if (heading >= 22.5 && heading < 67.5) {
        return @"NE";
    }
    else if (heading >= 67.5 && heading < 112.5) {
        return @"E";
    }
    else if (heading >= 112.5 && heading < 157.5) {
        return @"SE";
    }
    else if (heading >= 157.5 && heading < 202.5) {
        return @"S";
    }
    else if (heading >= 202.5 && heading < 247.5) {
        return @"SW";
    }
    else if (heading >= 247.5 && heading < 292.5) {
        return @"W";
    }
    else if (heading >= 292.5 && heading < 337.5) {
        return @"NW";
    }
    else
        return @"N";
}


void __alert(NSString* title, NSString* message, AlertAction okAction, AlertAction cancelAction, UIViewController* parent)
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:okAction];
    
    [alert addAction:ok];
    if (cancelAction) {
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:cancelAction];
        [alert addAction:cancel];
    }
    
    if (parent) {
        [parent presentViewController:alert animated:YES completion:nil];
    }
    else {
        [mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

NSString* __distanceString(double distance)
{
    if (distance > 500) {
        return [NSString stringWithFormat:@"FAR"];
    }
    else if (distance < 1.0f) {
        return [NSString stringWithFormat:@"%.0fm", distance*1000];
    }
    else {
        id fmt = (distance < 10.0) ? @"%.2fkm" : @"%.1fkm";
        return [NSString stringWithFormat:fmt, distance];
    }
}

CGFloat __ampAtIndex(NSUInteger index, NSData* data)
{
    static int c = 0;
    
    if (index >= data.length)
        return 0;
    
    NSData *d = [data subdataWithRange:NSMakeRange(index, 1)];
    [d getBytes:&c length:1];
    CGFloat ret = ((CGFloat)c) / 256.0f;
    return ret;
}

void __setShadowOnView(UIView* view, CGFloat radius, CGFloat opacity)
{
    view.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:1.0f].CGColor;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = radius;
    view.layer.shadowOpacity = opacity;
}

CGFloat __widthForNumberOfCells(UICollectionView* cv, UICollectionViewFlowLayout *flowLayout, CGFloat cpr)
{
    return (CGRectGetWidth(cv.bounds) - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (cpr - 1))/cpr;
}

UIView* __viewWithTag(UIView *view, NSInteger tag)
{
    __block UIView *retView = nil;
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == tag) {
            retView = obj;
            *stop = YES;
        }
    }];
    return retView;
}

PFGeoPoint* __pointFromCLLocation(CLLocation* location)
{
    return [PFGeoPoint geoPointWithLocation:location];
}

PFGeoPoint* __pointFromCoordinates(CLLocationCoordinate2D  coordinates)
{
    return [PFGeoPoint geoPointWithLatitude:coordinates.latitude longitude:coordinates.longitude];
}

id __dictionary(id object)
{
    if ([object isKindOfClass:[PFObject class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        
        PFObject *o = object;
        if (o.objectId)
            dictionary[fObjectId] = o.objectId;
        if (o.createdAt)
            dictionary[fCreatedAt] = o.createdAt;
        if (o.updatedAt)
            dictionary[fUpdatedAt] = o.updatedAt;
        
        [((PFObject*)object).allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            id value = [object objectForKey:key];
            [dictionary setObject:__dictionary(value) forKey:key];
        }];
        
        return dictionary;
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        NSLog(@"@[");
        [object enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [array addObject:__dictionary(obj)];
        }];
        NSLog(@"]");
        return array;
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        
        NSLog(@"@{");
        [((NSDictionary*)object).allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            id value = [object objectForKey:key];
            [dictionary setObject:__dictionary(value) forKey:key];
        }];
        NSLog(@"}");
        return dictionary;
    }
    else if ([object isKindOfClass:[PFACL class]]) {
        NSLog(@">>PFACL");
        return NSStringFromClass([object class]);
    }
    else if ([object isKindOfClass:[PFGeoPoint class]]) {
        NSLog(@">>PFGeo");
        PFGeoPoint *w = object;
        return @{ @"latitude" : @(w.latitude), @"longitude" : @(w.longitude) };
    }
    else {
        NSLog(@">> %@[%@]", NSStringFromClass([object class]), object);
        return object;
    }
}

@implementation NSDate (extensions)

-(NSDate *) dateWithoutTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    return [calendar dateFromComponents:components];
}

+ (NSDate*) dateFromStringUTC:(NSString*)string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    return [dateFormatter dateFromString:string];
}

- (NSString*) stringUTC
{
    static NSDateFormatter *dateFormatter = nil;
    
    if (!dateFormatter) {
        dateFormatter = [NSDateFormatter new];
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:locale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    }
    return [dateFormatter stringFromDate:self];
}

@end


@implementation PFGeoPoint (extensions)

+ (instancetype) geoPointFromWhere:(id)where
{
    return [PFGeoPoint geoPointWithLatitude:[where[fLatitude] floatValue] longitude:[where[fLongitude] floatValue]];
}

- (CLLocationDegrees)headingToLocation:(PFGeoPoint *)location
{
    float fLat = degreesToRadians(self.latitude);
    float fLng = degreesToRadians(self.longitude);
    float tLat = degreesToRadians(location.latitude);
    float tLng = degreesToRadians(location.longitude);
    
    float degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
    
    if (degree >= 0) {
        return degree;
    } else {
        return 360+degree;
    }
}

- (CGFloat) headingInRadiansToLocation:(PFGeoPoint*)location
{
    float fLat = degreesToRadians(self.latitude);
    float fLng = degreesToRadians(self.longitude);
    float tLat = degreesToRadians(location.latitude);
    float tLng = degreesToRadians(location.longitude);
    
    return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
}

- (NSString*) distanceStringToLocation:(PFGeoPoint *)location
{
    CGFloat distance = [self distanceInKilometersTo:location];
    return __distanceString(distance);
}

#define commaSpace @", "
#define formattedAddressLines @"FormattedAddressLines"
- (void) reverseGeocode:(StringBlock)handler
{
    NSString* errorString = @"Address not found";
    
    CLGeocoder *geocoder = [CLGeocoder new];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {

        if (error) {
            NSLog(@"failed with error: %@", error);
            if (handler) {
                handler(errorString);
            }
        }
        
        if (placemarks.count > 0)
        {
            NSString *address = @"";
            
            CLPlacemark* placemark = [placemarks firstObject];
            id dic = placemark.addressDictionary;
            
            if([placemark.addressDictionary objectForKey:formattedAddressLines] != NULL) {
                address = [[dic objectForKey:formattedAddressLines] componentsJoinedByString:commaSpace];
            }
            else {
                address = errorString;
            }
            
            if (handler) {
                handler(address);
            }
        }
        else {
            if (handler) {
                handler(errorString);
            }
        }
    }];
}
#undef commaSpace
#undef formattedAddressLines

@end

@implementation User (extensions)

- (CLLocationDegrees)headingToUser:(User *)user
{
    return [self.where headingToLocation:user.where];
}
@end

@implementation UIColor (extensions)

- (NSString*) stringValue
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    return [NSString stringWithFormat:@"[%f, %f, %f, %f]",
            components[0],
            components[1],
            components[2],
            components[3]];
}

+ (UIColor*) colorFromString:(NSString*)colorString
{
    NSString *componentsString = [[colorString stringByReplacingOccurrencesOfString:@"[" withString:kStringNull] stringByReplacingOccurrencesOfString:@"]" withString:kStringNull];
    NSArray *components = [componentsString componentsSeparatedByString:kStringCommaSpace];
    return [UIColor colorWithRed:[(NSString*)components[0] floatValue]
                           green:[(NSString*)components[1] floatValue]
                            blue:[(NSString*)components[2] floatValue]
                           alpha:[(NSString*)components[3] floatValue]];
}

+ (UIColor*) maleColor
{
    return [UIColor colorWithRed:95/255.f green:167/255.f blue:229/255.f alpha:1.0f];
}

+ (UIColor *)femaleColor
{
    return [UIColor colorWithRed:255/255.f green:35/255.f blue:35/255.f alpha:1.0f];
}

+ (UIColor*) appColor
{
    return kAppColor;
}

+ (UIColor *)unknownGenderColor
{
    return [UIColor colorWithRed:128/255.f green:128/255.f blue:128/255.f alpha:1.0f];
}

- (UIColor *)grayscale
{
    CGFloat red = 0;
    CGFloat blue = 0;
    CGFloat green = 0;
    CGFloat alpha = 0;
 
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return [UIColor colorWithWhite:(0.299*red + 0.587*green + 0.114*blue) alpha:alpha];
    } else {
        return self;
    }
}

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;

    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    }
    else {
        return self;
    }
}

- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    }
    else {
        return self;
    }
}

+ (UIColor *)interpolateRGBColorFrom:(UIColor *)startColor
                                  to:(UIColor *)endColor
                        withFraction:(float)f
{
    UIColor *start = [UIColor colorWithCGColor:CGColorCreateCopyByMatchingToColorSpace(CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGRenderingIntentDefault, startColor.CGColor, NULL)];
    UIColor *end = [UIColor colorWithCGColor:CGColorCreateCopyByMatchingToColorSpace(CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGRenderingIntentDefault, endColor.CGColor, NULL)];
    
    f = MAX(0, f);
    f = MIN(1, f);
    
    const CGFloat *c1 = CGColorGetComponents(start.CGColor);
    const CGFloat *c2 = CGColorGetComponents(end.CGColor);
    
    CGFloat r = c1[0] + (c2[0] - c1[0]) * f;
    CGFloat g = c1[1] + (c2[1] - c1[1]) * f;
    CGFloat b = c1[2] + (c2[2] - c1[2]) * f;
    CGFloat a = c1[3] + (c2[3] - c1[3]) * f;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+ (UIColor *)interpolateHSVColorFrom:(UIColor *)startColor to:(UIColor *)endColor withFraction:(float)f
{
    UIColor *start = [UIColor colorWithCGColor:CGColorCreateCopyByMatchingToColorSpace(CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGRenderingIntentDefault, startColor.CGColor, NULL)];
    UIColor *end = [UIColor colorWithCGColor:CGColorCreateCopyByMatchingToColorSpace(CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGRenderingIntentDefault, endColor.CGColor, NULL)];

    f = MAX(0, f);
    f = MIN(1, f);
    
    CGFloat h1,s1,v1,a1;
    [start getHue:&h1 saturation:&s1 brightness:&v1 alpha:&a1];
    
    CGFloat h2,s2,v2,a2;
    [end getHue:&h2 saturation:&s2 brightness:&v2 alpha:&a2];
    
    CGFloat h = h1 + (h2 - h1) * f;
    CGFloat s = s1 + (s2 - s1) * f;
    CGFloat v = v1 + (v2 - v1) * f;
    CGFloat a = a1 + (a2 - a1) * f;
    
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:a];
}

@end

@implementation NSString (extensions)

- (CGFloat) heightWithFont:(UIFont*)font maxWidth:(CGFloat)width
{
    return CGRectGetHeight([self boundingRectWithFont:font maxWidth:width]);
}

- (CGRect) boundingRectWithFont:(UIFont*)font maxWidth:(CGFloat) width
{
    CGSize size = CGSizeMake(width, MAXFLOAT);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin;
    id attributes = @{ NSFontAttributeName: font};
    
    return CGRectIntegral([self boundingRectWithSize:size
                                             options:options
                                          attributes:attributes
                                             context:nil]);
}

- (NSString*) substringWithNumberOfWords:(NSUInteger)count
{
    
    NSArray *words = [self componentsSeparatedByString:@" "];
    return [[words subarrayWithRange:NSMakeRange(0, MIN(count, words.count) - 1)] componentsJoinedByString:@" "];
}

- (UIColor*) UIColor
{
    NSString *componentsString = [[self stringByReplacingOccurrencesOfString:@"[" withString:kStringNull] stringByReplacingOccurrencesOfString:@"]" withString:kStringNull];
    NSArray *components = [componentsString componentsSeparatedByString:kStringCommaSpace];
    return [UIColor colorWithRed:[(NSString*)components[0] floatValue]
                           green:[(NSString*)components[1] floatValue]
                            blue:[(NSString*)components[2] floatValue]
                           alpha:[(NSString*)components[3] floatValue]];
}

-(BOOL) isValidEmail
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}
@end

@implementation PFConfig (extensions)

+ (id) objectForLocaleKey:(id)key
{
    return [[PFConfig currentConfig] objectForLocaleKey:key];
}

- (id) objectForLocaleKey:(id)key
{
    NSString *localeCode = [[[[NSLocale preferredLanguages] objectAtIndex:0] componentsSeparatedByString:@"-"] firstObject];;
    
    PFConfig* config = [PFConfig currentConfig];
    NSString *loc = [key stringByAppendingString:localeCode];
    id ret = [config objectForKey:loc];
    if (ret == nil) { // if no configuration then try without locale code.
        return [config objectForKey:key];
    }
    return ret;
}
@end

@implementation UIView (extensions)

- (void)drawImage:(UIImage *)image
{
    [self.layer setContents:(id)image.CGImage];
    [self.layer setContentsGravity:kCAGravityResizeAspectFill];
    [self.layer setMasksToBounds:YES];
}

@end

@implementation UIImage (extensions)

+(UIImage *)avatar
{
    return [UIImage imageNamed:@"avatar"];
}

@end

