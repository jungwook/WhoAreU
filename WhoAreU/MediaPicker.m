//
//  MediaPicker.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 23..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "MediaPicker.h"
#import "S3File.h"
#import "AppDelegate.h"

#define kThumbnailWidth 50
#define kVideoThumbnailWidth 320

@import MobileCoreServices;

@interface MediaPicker ()
@property (nonatomic, copy) MediaInfoBlock userMediaInfoBlock;
@property (nonatomic, copy) MediaBlock userMediaBlock;
@property (nonatomic, copy) MediaDataBlock mediaBlock;
@end

@implementation MediaPicker

NSString* randomObjectId()
{
    int length = 8;
    char *base62chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    
    NSString *code = @"";
    
    for (int i=0; i<length; i++) {
        int rand = arc4random_uniform(36);
        code = [code stringByAppendingString:[NSString stringWithFormat:@"%c", base62chars[rand]]];
    }
    
    return code;
}

CALayer* drawImageOnLayer(UIImage *image, CGSize size)
{
    CALayer *layer = [CALayer layer];
    [layer setBounds:CGRectMake(0, 0, size.width, size.height)];
    [layer setContents:(id)image.CGImage];
    [layer setContentsGravity:kCAGravityResizeAspect];
    [layer setMasksToBounds:YES];
    return layer;
}

UIImage* scaleImage(UIImage* image, CGSize size) {
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
    [drawImageOnLayer(image,size) renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return smallImage;
}

NSData* compressedImageData(NSData* data, CGFloat width)
{
    UIImage *image = [UIImage imageWithData:data];
    const CGFloat thumbnailWidth = width;
    CGFloat thumbnailHeight = image.size.width ? thumbnailWidth * image.size.height / image.size.width : 200;
    image = scaleImage(image, CGSizeMake(thumbnailWidth, thumbnailHeight));
    return UIImageJPEGRepresentation(image, kJPEGCompressionMedium);
}

typedef void(^ActionHandlers)(UIAlertAction * _Nonnull action);

+ (void) pickMediaOnViewController:(UIViewController*)viewController withMediaInfoHandler:(MediaInfoBlock)handler
{
    NSAssert(viewController != nil, @"View Controller cannot be nil");
    UIViewController* vc = viewController;
    [MediaPicker handleAlertOnViewController:vc
                              libraryHandler:^(UIAlertAction * _Nonnull action) {
        [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                                  userMediaInfoBlock:handler]
                                     animated:YES
                                   completion:nil];
    }
                               cameraHandler:^(UIAlertAction * _Nonnull action) {
        [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                                  userMediaInfoBlock:handler]
                                     animated:YES
                                   completion:nil];
    } userMediaInfoBlock:handler mediaBlock:nil userMediaBlock:nil];
}

+ (void) pickMediaOnViewController:(UIViewController *)viewController withUserMediaHandler:(MediaBlock)handler
{
    NSAssert(viewController != nil, @"View Controller cannot be nil");
    UIViewController* vc = viewController;
    [MediaPicker handleAlertOnViewController:vc
                              libraryHandler:^(UIAlertAction * _Nonnull action) {
                                  [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary userMediaBlock:handler]
                                                               animated:YES
                                                             completion:nil];
                              }
                               cameraHandler:^(UIAlertAction * _Nonnull action) {
                                   [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypeCamera userMediaBlock:handler]
                                                                animated:YES
                                                              completion:nil];
                               }
                          userMediaInfoBlock:nil
                                  mediaBlock:nil
                              userMediaBlock:handler];
}

+ (void)pickMediaOnViewController:(UIViewController *)viewController withMediaHandler:(MediaDataBlock)handler
{
    NSAssert(viewController != nil, @"View Controller cannot be nil");
    UIViewController* vc = viewController;
    [MediaPicker handleAlertOnViewController:vc
                              libraryHandler:^(UIAlertAction * _Nonnull action) {
                                  [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary mediaBlock:handler]
                                                   animated:YES
                                                 completion:nil];
                              }
                               cameraHandler:^(UIAlertAction * _Nonnull action) {
                                   [vc presentViewController:[MediaPicker mediaPickerWithSourceType:UIImagePickerControllerSourceTypeCamera mediaBlock:handler]
                                                    animated:YES
                                                  completion:nil];
                               }
                          userMediaInfoBlock:nil
                                  mediaBlock:handler
                              userMediaBlock:nil];
}

+ (instancetype) mediaPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType userMediaInfoBlock:(MediaInfoBlock)block
{
    return [[MediaPicker alloc] initWithSourceType:sourceType userMediaInfoBlock:block];
}

+ (instancetype) mediaPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType userMediaBlock:(MediaBlock)block
{
    return [[MediaPicker alloc] initWithSourceType:sourceType userMediaBlock:block];
}

+ (instancetype) mediaPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType mediaBlock:(MediaDataBlock)block
{
    return [[MediaPicker alloc] initWithSourceType:sourceType mediaBlock:block];
}


- (instancetype) initWithSourceType:(UIImagePickerControllerSourceType)sourceType userMediaInfoBlock:(MediaInfoBlock)block
{
    self = [super init];
    if (self) {
        [self selfInitializersWithSourceType:sourceType userMediaInfoBlock:block userMediaBlock:nil mediaBlock:nil];
    }
    return self;
}

- (instancetype) initWithSourceType:(UIImagePickerControllerSourceType)sourceType userMediaBlock:(MediaBlock)block
{
    self = [super init];
    if (self) {
        [self selfInitializersWithSourceType:sourceType userMediaInfoBlock:nil userMediaBlock:block mediaBlock:nil];
    }
    return self;
}

- (instancetype) initWithSourceType:(UIImagePickerControllerSourceType)sourceType mediaBlock:(MediaDataBlock)block
{
    self = [super init];
    if (self) {
        [self selfInitializersWithSourceType:sourceType userMediaInfoBlock:nil userMediaBlock:nil mediaBlock:block];
    }
    return self;
}

- (void) selfInitializersWithSourceType:(UIImagePickerControllerSourceType)sourceType
                     userMediaInfoBlock:(MediaInfoBlock)userMediaInfoBlock
                         userMediaBlock:(MediaBlock)userMediaBlock
                             mediaBlock:(MediaDataBlock)mediaBlock
{
    self.delegate = self;
    self.allowsEditing = YES;
    self.videoMaximumDuration = 10;
    self.sourceType = sourceType;
    self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    self.userMediaInfoBlock = userMediaInfoBlock;
    self.userMediaBlock = userMediaBlock;
    self.mediaBlock = mediaBlock;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.mediaBlock) {
        self.mediaBlock( NO, nil, nil, nil, NO, NO);
    }
    else if (self.userMediaBlock) {
        self.userMediaBlock(nil, NO);
    }
    else if (self.userMediaInfoBlock) {
        self.userMediaInfoBlock(NO, nil, nil, nil, CGSizeZero, NO, NO);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    NSURL *url = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
    
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        [self handlePhoto:info url:url source:picker.sourceType];
    }
    else if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)== kCFCompareEqualTo) {
        [self handleVideo:info url:url source:picker.sourceType];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void) handlePhoto:(NSDictionary<NSString*, id>*)info url:(NSURL*)url source:(UIImagePickerControllerSourceType)sourceType
{
    BOOL isReal = (sourceType == UIImagePickerControllerSourceTypeCamera);
    // Original image
    UIImage *image = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
    
    // Original image data
    NSData *imageData = UIImageJPEGRepresentation(image, kJPEGCompressionFull);
    
    // Thumbnail data
    NSData *thumbnailData = compressedImageData(imageData, kThumbnailWidth);
    
    if (self.mediaBlock) {
        self.mediaBlock(kMediaTypePhoto, thumbnailData, imageData, nil, isReal, YES);
    }
    else {
        NSString *thumbFileName = [S3File saveImageData:thumbnailData completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error) {
             if (error) {
                 NSLog(@"ERROR:%@", error.localizedDescription);
             }
         } progressBlock:nil];
        
        NSString *mediaFileName = [S3File saveImageData:imageData completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"ERROR:%@", error.localizedDescription);
            }
        }];

        if (self.userMediaBlock) {
            Media *media = [Media object];
            media.size = image.size;
            media.media = mediaFileName;
            media.thumbnail = thumbFileName;
            media.type = kMediaTypePhoto;
            media.source = isReal;
            self.userMediaBlock(media, YES);
        }
        if (self.userMediaInfoBlock) {
            self.userMediaInfoBlock( kMediaTypePhoto, thumbnailData, thumbFileName, mediaFileName, image.size, isReal, YES);
        }
    }
}

- (void) handlePhotoCopy:(NSDictionary<NSString*, id>*)info url:(NSURL*)url source:(UIImagePickerControllerSourceType)sourceType
{
    BOOL isReal = (sourceType == UIImagePickerControllerSourceTypeCamera);
    // Original image
    UIImage *image = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
    
    // Original image data
    NSData *imageData = UIImageJPEGRepresentation(image, kJPEGCompressionFull);
    
    // Thumbnail data
    NSData *thumbnailData = compressedImageData(imageData, kThumbnailWidth);
    
    if (self.mediaBlock) {
        self.mediaBlock(kMediaTypePhoto, thumbnailData, imageData, nil, isReal, YES);
    }
    else {
        [S3File saveImageData:thumbnailData completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error)
         {
             if (succeeded && !error) {
                 [S3File saveImageData:imageData completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
                     
                     if (succeeded && !error) {
                         if (self.userMediaInfoBlock) {
                             self.userMediaInfoBlock( kMediaTypePhoto,
                                                     thumbnailData,
                                                     thumbnailFile,
                                                     mediaFile,
                                                     image.size,
                                                     isReal, YES);
                         }
                         
                         if (self.userMediaBlock) {
                             Media *media = [Media object];
                             media.size = image.size;
                             media.media = mediaFile;
                             media.thumbnail = thumbnailFile;
                             media.type = kMediaTypePhoto;
                             media.source = isReal;
                             
                             self.userMediaBlock(media, YES);
                         }
                     }
                     else {
                         NSLog(@"ERROR:%@", error.localizedDescription);
                     }
                 }];
             }
             else {
                 NSLog(@"ERROR:%@", error.localizedDescription);
             }
         } progressBlock:nil];
    }
}

- (void) handleVideo:(NSDictionary<NSString*, id>*)info url:(NSURL*)url source:(UIImagePickerControllerSourceType)sourceType
{
    BOOL isReal = (sourceType == UIImagePickerControllerSourceTypeCamera);
    NSString *tempId = randomObjectId();
    NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:tempId]];
    
    // Video Asset
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    // Thumbnail Image
    UIImage *thumbnailImage = [self thumbnailFromVideoAsset:asset source:sourceType];
    
    // Thumbnail Image data @ full compression
    NSData *thumbnailData = compressedImageData(UIImageJPEGRepresentation(thumbnailImage, kJPEGCompressionFull), kVideoThumbnailWidth);

    if (self.mediaBlock)
    {
        [self convertVideoToLowQuailtyWithInputURL:url outputURL:outputURL handler:^(AVAssetExportSession *exportSession) {
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSData *videoData = [NSData dataWithContentsOfURL:outputURL];
                self.mediaBlock(kMediaTypeVideo, thumbnailData, nil, videoData, isReal, YES);
                [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
            }
        }];
    }
    else {
        [S3File saveImageData:thumbnailData completedBlock:^(NSString *thumbnailFile, BOOL succeeded, NSError *error) {
            [self convertVideoToLowQuailtyWithInputURL:url outputURL:outputURL handler:^(AVAssetExportSession *exportSession) {
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    NSData *videoData = [NSData dataWithContentsOfURL:outputURL];
                    
                    [S3File saveMovieData:videoData completedBlock:^(NSString *mediaFile, BOOL succeeded, NSError *error) {
                        if (succeeded && !error) {
                            if (self.userMediaInfoBlock) {
                                self.userMediaInfoBlock(kMediaTypeVideo,
                                                        thumbnailData,
                                                        thumbnailFile,
                                                        mediaFile,
                                                        thumbnailImage.size,
                                                        isReal,
                                                        YES);
                            }
                            
                            if (self.userMediaBlock) {
                                Media *media = [Media object];
                                media.size = thumbnailImage.size;
                                media.media = mediaFile;
                                media.thumbnail = thumbnailFile;
                                media.type = kMediaTypeVideo;
                                media.source = isReal;
                                
                                self.userMediaBlock(media, YES);
                            }
                        }
                        else {
                            NSLog(@"ERROR:%@", error.localizedDescription);
                        }
                        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
                    }];
                }
            }];
        } progressBlock:nil];
    }
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1920x1080];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
}

- (UIImage*) thumbnailFromVideoAsset:(AVAsset*)asset source:(UIImagePickerControllerSourceType)sourceType
{
    __LF
    AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generateImg.appliesPreferredTrackTransform = YES;
    
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:[generateImg copyCGImageAtTime:CMTimeMake(1, 1) actualTime:NULL error:nil]];
    return thumbnail;
}

+ (void) handleAlertOnViewController:(UIViewController*)viewController
                      libraryHandler:(ActionHandlers)library
                       cameraHandler:(ActionHandlers)camera
                  userMediaInfoBlock:(MediaInfoBlock)mediaInfoBlock
                          mediaBlock:(MediaDataBlock)mediaBlock
                      userMediaBlock:(MediaBlock)userMediaBlock

{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Library"
                                                  style:UIAlertActionStyleDefault
                                                handler:library]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Camera"
                                                  style:UIAlertActionStyleDefault
                                                handler:camera]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (mediaInfoBlock) {
            mediaInfoBlock( -1, nil, nil, nil, CGSizeZero, NO, NO);
        }
        if (mediaBlock) {
            mediaBlock(-1, nil, nil, nil, NO, NO);
        }
        if (userMediaBlock) {
            userMediaBlock(nil, NO);
        }
    }]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
