//
//  MediaPicker.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 23..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^MediaInfoBlock)(MediaType mediaType,
                                         NSData* thumbnailData,
                                         NSString* thumbnail,
                                         NSString* media,
                                         CGSize size,
                                         SourceType source,
                                         BOOL picked);

typedef void(^MediaDataBlock)(MediaType mediaType,
                                     NSData* thumbnailData,
                                     NSData* originalData,
                                     NSData* movieData,
                                     SourceType source,
                                     BOOL picked);

typedef void(^MediaBoolBlock)(Media* media, BOOL picked);

@interface MediaPicker : UIImagePickerController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

+ (void) pickMediaOnViewController:(UIViewController*)viewController withUserMediaHandler:(MediaBoolBlock)handler;
+ (void) pickMediaOnViewController:(UIViewController*)viewController withMediaInfoHandler:(MediaInfoBlock)handler;
+ (void) pickMediaOnViewController:(UIViewController*)viewController withMediaHandler:(MediaDataBlock)handler;
@end
