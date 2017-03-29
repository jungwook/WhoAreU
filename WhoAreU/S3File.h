//
//  S3File.h
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 9..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"

typedef void (^S3SimpleGetImageBlock)(UIImage* image);
typedef void (^S3SimpleGetBlock)(NSData *data);
typedef void (^S3GetBlock)(NSData * data, NSError * error, BOOL fromCache);
typedef void (^S3PutBlock)(NSString *file, BOOL succeeded, NSError * error);
typedef void (^S3ProgressBlock)(int percentDone);

@interface S3File : NSObject
+ (void) synchronize;
+ (void) getDataFromFile:(id)filename completedBlock:(S3GetBlock)block progressBlock:(S3ProgressBlock)progress;
+ (void) getDataFromFile:(id)filename completedBlock:(S3GetBlock)block;
+ (void) getDataFromFile:(id)filename dataBlock:(S3SimpleGetBlock)block;
+ (void) getImageFromFile:(id)filename imageBlock:(S3SimpleGetImageBlock)block;
+ (id) objectForKey:(id)key;

+ (NSString*) saveImageData:(NSData*)data;
+ (NSString*) saveMovieData:(NSData*)data;
+ (NSString*) saveAudioData:(NSData*)data;
+ (NSString*) saveMapImage:(UIImage*)image;

+ (NSString*) saveImageData:(NSData*)data completedBlock:(S3PutBlock)block;
+ (NSString*) saveMovieData:(NSData*)data completedBlock:(S3PutBlock)block;
+ (NSString*) saveAudioData:(NSData*)data completedBlock:(S3PutBlock)block;

+ (NSString*) saveImageData:(NSData*)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress;
+ (NSString*) saveMovieData:(NSData*)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress;
+ (NSString*) saveAudioData:(NSData*)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress;
+ (NSString*) saveImageData:(NSData*)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress;
+ (NSString*) saveMovieData:(NSData*)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress;
+ (NSString*) saveAudioData:(NSData*)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress;


+ (NSString*) saveSystemData:(NSData *)data named:(id)filename extension:(NSString*)extension completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress;
+ (NSString*) saveSystemDataInBackground:(NSData *)data named:(id)filename extension:(NSString*)extension;

@end