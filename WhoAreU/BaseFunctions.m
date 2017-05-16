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

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

float __heading(PFGeoPoint* fromLoc, PFGeoPoint* toLoc)
{
    float fLat = degreesToRadians(fromLoc.latitude);
    float fLng = degreesToRadians(fromLoc.longitude);
    float tLat = degreesToRadians(toLoc.latitude);
    float tLng = degreesToRadians(toLoc.longitude);
    
    float degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
    
    if (degree >= 0) {
        return degree;
    } else {
        return 360+degree;
    }
}

float __headingRad(PFGeoPoint* fromLoc, PFGeoPoint* toLoc)
{
    float fLat = degreesToRadians(fromLoc.latitude);
    float fLng = degreesToRadians(fromLoc.longitude);
    float tLat = degreesToRadians(toLoc.latitude);
    float tLng = degreesToRadians(toLoc.longitude);
    
    return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
}

float __headingUsers(User* from, User* to)
{
    PFGeoPoint *fromLoc = from.where;
    PFGeoPoint *toLoc = to.where;
    if (from != to && (fromLoc.latitude == toLoc.latitude && fromLoc.longitude == toLoc.longitude)) {
        printf("SAME LOCATION FOR:%s - %s\n", [from.nickname UTF8String], [to.nickname UTF8String]);
    }
    return __heading(fromLoc, toLoc);
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


void __alert(UIViewController* parent, NSString* title, NSString* message, AlertAction okAction, AlertAction cancelAction)
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:okAction];
    
    [alert addAction:ok];
    if (cancelAction) {
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:cancelAction];
        [alert addAction:cancel];
    }
    [parent presentViewController:alert animated:YES completion:nil];
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
        return [NSString stringWithFormat:@"%.0fkm", distance];
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

NSString *NSStringFromUIColor(UIColor *color)
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    return [NSString stringWithFormat:@"[%f, %f, %f, %f]",
            components[0],
            components[1],
            components[2],
            components[3]];
}

UIColor *UIColorFromNSString(NSString *string)
{
    NSString *componentsString = [[string stringByReplacingOccurrencesOfString:@"[" withString:kStringNull] stringByReplacingOccurrencesOfString:@"]" withString:kStringNull];
    NSArray *components = [componentsString componentsSeparatedByString:kStringCommaSpace];
    return [UIColor colorWithRed:[(NSString*)components[0] floatValue]
                           green:[(NSString*)components[1] floatValue]
                            blue:[(NSString*)components[2] floatValue]
                           alpha:[(NSString*)components[3] floatValue]];
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
