//
//  BaseFunctions.m
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseFunctions.h"
#import "MaterialDesignSymbol.h"

void __TT(VoidBlock action)
{
    [[NSOperationQueue new] addOperationWithBlock:action];
}

void __MT(VoidBlock action)
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:action];
}

BOOL Coords2DEquals(CLLocationCoordinate2D c1, CLLocationCoordinate2D c2)
{
    return (c1.latitude == c2.latitude && c1.longitude == c2.longitude);
}

BOOL Coords2DNotEquals(CLLocationCoordinate2D c1, CLLocationCoordinate2D c2)
{
    return !Coords2DEquals(c1, c2);
}

void __image(id file, ImageBlock action)
{
    [S3File getImageFromFile:file imageBlock:action];
}

CGPoint CGRectCenter(CGRect rect)
{
    return CGPointMake(rect.origin.x+rect.size.width/2.f, rect.origin.y+rect.size.height/2.f);
}

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

+ (UIColor *) colorFromHexString:(NSString *)hexString
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

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

@implementation NSAttributedString (extensions)

- (CGFloat)height
{
    return [self heightWithMaxWidth:FLT_MAX];
}

- (CGFloat)width
{
    return [self widthWithMaxWidth:FLT_MAX];
}

- (CGFloat) heightWithMaxWidth:(CGFloat)width
{
    return CGRectGetHeight([self boundingRectWithMaxWidth:width]);
}

- (CGFloat) widthWithMaxWidth:(CGFloat)width
{
    return CGRectGetWidth([self boundingRectWithMaxWidth:width]);
}

- (CGRect) boundingRectWithMaxWidth:(CGFloat)width
{
    CGSize size = CGSizeMake(width, MAXFLOAT);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin;
    return CGRectIntegral([self boundingRectWithSize:size options:options context:nil]);
}

@end

@implementation NSString (extensions)

- (CGFloat)heightWithFont:(UIFont *)font
{
    return [self heightWithFont:font maxWidth:FLT_MAX];
}

- (CGFloat)widthWithFont:(UIFont *)font
{
    return [self widthWithFont:font maxWidth:FLT_MAX];
}

- (CGFloat) heightWithFont:(UIFont*)font maxWidth:(CGFloat)width
{
    return CGRectGetHeight([self boundingRectWithFont:font maxWidth:width]);
}

- (CGFloat) widthWithFont:(UIFont*)font maxWidth:(CGFloat)width
{
    return CGRectGetWidth([self boundingRectWithFont:font maxWidth:width]);
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

- (BOOL) canBeEmail
{
    return [self containsString:@"@"];
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

+ (UIImage *)materialDesign:(NSString *)code
{
    return [[[MaterialDesignSymbol iconWithCode:code fontSize:48] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

@implementation UITableView (extensions)

- (void) registerNibNamed:(NSString *)name
{
    [self registerNib:[UINib nibWithNibName:name bundle:[NSBundle mainBundle]] forCellReuseIdentifier:name];
}

- (void) registerNibsNamed:(NSArray<NSString *> *)names
{
    [names enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerNibNamed:name];
    }];
}
@end

@implementation UICollectionView (extensions)

- (void) registerNibsNamed:(NSArray<NSString *> *)names
{
    [names enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerNibNamed:name];
    }];
}

- (void) registerNibNamed:(NSString *)name
{
    [self registerNib:[UINib nibWithNibName:name bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:name];
}

- (__kindof UICollectionViewCell *) visibleCell
{
    CGRect shownFrame = self.bounds;
    shownFrame.origin = self.contentOffset;
    
    return [self.visibleCells sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewCell* _Nonnull c1, UICollectionViewCell* _Nonnull c2) {
        
        CGRect r1 = CGRectIntersection(shownFrame, c1.frame);
        CGRect r2 = CGRectIntersection(shownFrame, c2.frame);
        CGFloat h1 = CGRectGetWidth(r1)*CGRectGetHeight(r1);
        CGFloat h2 = CGRectGetWidth(r2)*CGRectGetHeight(r2);
        
        return (h1 > h2) ? NSOrderedAscending : (h1 < h2) ? NSOrderedDescending : NSOrderedSame;
    }].firstObject;
}
@end

@implementation NSArray (extensions)

- (NSArray<User*>*) sortedArrayOfUsersByDistance:(NSArray<User*>*)users
{
    User *user = [User me];
    return [users sortedArrayUsingComparator:^NSComparisonResult(User*  _Nonnull user1, User*  _Nonnull user2) {
        CGFloat distanceA = [user.where distanceInKilometersTo:user1.where];
        CGFloat distanceB = [user.where distanceInKilometersTo:user2.where];
        
        if (distanceA < distanceB) {
            return NSOrderedAscending;
        } else if (distanceA > distanceB) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (id)objectAtIndexRow:(NSIndexPath *)indexPath
{
    return [self objectAtIndex:indexPath.row];
}

- (void)concurrentBlocksUsingObjects:(void (^)(id, NSUInteger, BOOL *))block
{
    
}
@end

NSString const *topRadiusKey = @"UIView_topRadiusKey";

@implementation UIView(Radius)
@dynamic radius;

-(void) setRadius:(CGFloat)radius
{
    self.layer.cornerRadius = radius;
}

-(CGFloat) radius
{
    return self.layer.cornerRadius;
}

@end

@implementation UIView(Extras)
@dynamic borderColor, shadowRadius, topRadius;

- (void)setTopRadius:(CGFloat)topRadius
{
    NSNumber *number = @(topRadius);
    objc_setAssociatedObject(self, &topRadiusKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = [self rountTopCornerPathWithRadius:topRadius].CGPath;
    
    self.layer.mask = mask;
}

-(CGFloat)topRadius
{
    NSNumber *number = objc_getAssociatedObject(self, &topRadiusKey);
    return number.floatValue;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (shadowRadius > 0) {
        self.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:1.0f].CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = shadowRadius;
        self.layer.shadowOpacity = 0.4f;
    }
    else {
        self.layer.shadowColor = nil;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 0.0f;
        self.layer.shadowOpacity = 0.0f;
    }
}

- (CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

- (UIBezierPath*) rountTopCornerPathWithRadius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath new];
    CGFloat w = self.frame.size.width, h = self.frame.size.height, i = radius;
    
    [path moveToPoint:CGPointMake(0, i)];
    [path addQuadCurveToPoint:CGPointMake(i, 0) controlPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(w-i, 0)];
    [path addQuadCurveToPoint:CGPointMake(w, i) controlPoint:CGPointMake(w, 0)];
    [path addLineToPoint:CGPointMake(w, h)];
    [path addLineToPoint:CGPointMake(0, h)];
    [path addLineToPoint:CGPointMake(0, i)];
    
    return path;
}

@end


@implementation UILabel(Shadow)
@dynamic shadow;

- (void)setShadow:(BOOL)shadow
{
    if (shadow) {
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.4;
    }
    else {
        self.layer.shadowColor = nil;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 0;
        self.layer.shadowOpacity = 0;
    }
}

- (BOOL)shadow
{
    return (BOOL) self.layer.shadowColor;
}

@end

@implementation UIScrollView (NormalizedContentOffset)

- (CGPoint)normalizedOffset
{
    return CGPointMake(self.contentOffset.x + self.contentInset.left, self.contentOffset.y + self.contentInset.top);
}

@end

@implementation MKMapView (extensions)

- (id<MKAnnotation>)annotationClosestToCenter
{
    CGFloat closest = FLT_MAX;
    __block id <MKAnnotation> closestAnnotation = nil;
    [self.visibleAnnotations enumerateObjectsUsingBlock:^(id<MKAnnotation> _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        CLLocation *l = LocationFromCoords(annotation.coordinate);
        CLLocation *center = LocationFromCoords(self.centerCoordinate);
        CGFloat d = [l distanceFromLocation:center];
        if (closest > d) {
            d = closest;
            closestAnnotation = annotation;
        }
    }];
    return closestAnnotation;
}

- (NSArray<id<MKAnnotation>> *)visibleAnnotations
{
    return [self annotationsInMapRect:self.visibleMapRect].allObjects;
}

- (__kindof MKAnnotationView *)annotationViewClosesToCenterWithClass:(__unsafe_unretained Class)classType
{
    MKAnnotationView *view = [self viewForAnnotation:[self annotationClosestToCenterWithClass:classType]];
    return view;
}

- (id<MKAnnotation>)annotationClosestToCenterWithClass:(__unsafe_unretained Class)classType
{
    __block CGFloat closest = FLT_MAX;
    __block id <MKAnnotation> closestAnnotation = nil;
    [self.visibleAnnotations enumerateObjectsUsingBlock:^(id<MKAnnotation> _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([annotation isKindOfClass:classType]) {
            CLLocation *l = LocationFromCoords(annotation.coordinate);
            CLLocation *center = LocationFromCoords(self.centerCoordinate);
            CGFloat d = [l distanceFromLocation:center];
            if (closest > d) {
                closest = d;
                closestAnnotation = annotation;
            }
        }
        else {
        }
    }];
    return closestAnnotation;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated
{
    CGFloat width = CGRectGetWidth(self.frame);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360.f/pow(2, zoomLevel)*width/256);
    [self setRegion:MKCoordinateRegionMake(centerCoordinate, span) animated:animated];
}

- (void)setZoomLevel:(CGFloat)zoomLevel animated:(BOOL)animated
{
    CGFloat width = CGRectGetWidth(self.frame);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360.f/pow(2, zoomLevel)*width/256);
    [self setRegion:MKCoordinateRegionMake(self.centerCoordinate, span) animated:animated];
}

- (void)setZoomLevel:(CGFloat)zoomLevel
{
    [self setZoomLevel:zoomLevel animated:NO];
}

-(CGFloat)zoomLevel
{
    return log2(360 * ((self.frame.size.width/256) / self.region.span.longitudeDelta));
}

@end


@interface Operations ()
@property (nonatomic) NSUInteger operationsPerThread;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSBlockOperation *completionBlock;
@end

@implementation Operations

+ (instancetype)operationsWithCompletionBlock:(VoidBlock)action
{
    Operations *op = [Operations new];
    op.completionBlock = [NSBlockOperation blockOperationWithBlock:action];
    
    return op;
}

+ (instancetype)operationsWithCompletionBlock:(VoidBlock)action operationsPerThread:(NSUInteger)operationsPerThread
{
    Operations *op = [Operations new];
    op.completionBlock = [NSBlockOperation blockOperationWithBlock:action];
    op.operationsPerThread = operationsPerThread;
    
    return op;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupVariables];
    }
    return self;
}

- (void)setupVariables
{
    self.queue = [NSOperationQueue new];
    self.operationsPerThread = 11;
}

- (void)setOperationsPerThread:(NSUInteger)operationsPerThread
{
    _operationsPerThread = operationsPerThread;
    self.queue.maxConcurrentOperationCount = self.operationsPerThread;
}

- (void)addOperationsFromArrayOfObject:(NSArray*)objects execution:(ObjectIndexBlock _Nonnull)action
{
    [[NSOperationQueue new] addOperationWithBlock:^{
        [objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                action(obj, idx);
            }];
            [self.queue addOperation:blockOperation];
        }];
        [self.queue waitUntilAllOperationsAreFinished];
        [self.queue addOperation:self.completionBlock];
    }];
}
@end

void dispatch_background(VoidBlock action)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), action);
}

void dispatch_foreground(VoidBlock action)
{
    dispatch_async(dispatch_get_main_queue(), action);
}

void dispatch(long identifier, VoidBlock action)
{
    dispatch_async(dispatch_get_global_queue(identifier, 0), action);
}

