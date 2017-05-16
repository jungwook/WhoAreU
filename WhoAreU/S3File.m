//
//  S3File.m
//  LetsMeet
//
//  Created by 한정욱 on 2016. 6. 9..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "S3File.h"
#import "ObjectIdStore.h"

@interface S3File ()
@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) NSURL* cachePath, *dataPath;
@end


@implementation S3File

+ (instancetype) file
{
    static id sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[self alloc] init];
    });
    return sharedFile;
}

+ (NSString*) s3bucket
{
    return @"whoareu";
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        NSURL* applicationPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL* systemPath = [applicationPath URLByAppendingPathComponent:@"Engine"];
        self.cachePath = [systemPath URLByAppendingPathComponent:@"MediaCache"];
        self.dataPath = [systemPath URLByAppendingPathComponent:@"DataCache"];
        
        [self createSystemPaths];
        
        self.cache = [NSMutableDictionary dictionaryWithContentsOfURL:self.cachePath];
        if (!self.cache) {
            self.cache = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

- (void) createSystemPaths
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    BOOL ret = [manager createDirectoryAtURL:self.cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!ret || error) {
        NSLog(@"ERROR:%@", error.localizedDescription);
        NSLog(@"ERROR:%@", error.localizedRecoverySuggestion);
    } else {
        NSLog(@"SYSTEM & MESSAGES PATH[%@] SUCCESSFULLY SETUP", [self.cachePath path]);
    }
    ret = [manager createDirectoryAtURL:self.dataPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!ret || error) {
        NSLog(@"ERROR:%@", error.localizedDescription);
        NSLog(@"ERROR:%@", error.localizedRecoverySuggestion);
    } else {
        NSLog(@"SYSTEM & MESSAGES PATH[%@] SUCCESSFULLY SETUP", [self.dataPath path]);
    }
}

+ (id)objectForKey:(id)key
{
    return [[S3File file] objectForKey:key];
}

+ (void) getDataFromFile:(id)filename completedBlock:(S3GetBlock)block progressBlock:(S3ProgressBlock)progress
{
    [[S3File file] getDataFromFile:filename completedBlock:block progressBlock:progress];
}

+ (void) getDataFromFile:(id)filename completedBlock:(S3GetBlock)block
{
    [[S3File file] getDataFromFile:filename completedBlock:block progressBlock:nil];
}

+ (void)getImageFromFile:(id)filename imageBlock:(S3SimpleGetImageBlock)block
{
    if (filename) {
        [[S3File file] getDataFromFile:filename completedBlock:^(NSData *data, NSError *error, BOOL fromCache) {
            if (error) {
                NSLog(@"ERROR:%@", error.localizedDescription);
                if (block) {
                    block(nil);
                }
            }
            else {
                if (block) {
                    block([UIImage imageWithData:data]);
                }
            }
        } progressBlock:nil];
    }
    else {
        NSLog(@"ERROR:%@", @"Nil filename provided.");
        block(nil);
    }
}

+ (void)getDataFromFile:(id)filename dataBlock:(S3SimpleGetBlock)block
{
    [[S3File file] getDataFromFile:filename completedBlock:^(NSData *data, NSError *error, BOOL fromCache) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
            if (block) {
                block(nil);
            }
        }
        else {
            if (block) {
                block(data);
            }
        }
    } progressBlock:nil];
}

- (id) objectForKey:(id)key
{
    NSError *error = nil;

    if (!key) {
        NSLog(@"ERROR: Cannot retrieve data from (null) key");
        return nil;
    }
    
    id cacheItem = [self.cache objectForKey:key];
    if (cacheItem) {
        return cacheItem[@"data"];
    }
    else {
        NSData *data = [NSData dataWithContentsOfURL:[self.dataPath URLByAppendingPathComponent:[key lastPathComponent]] options:NSDataReadingUncached error:&error];

        if (data) {
            @synchronized (self.cache) {
                id cacheItem = @{ fUpdatedAt : [NSDate date],
                                  @"data" : data };
                
                [self.cache setObject:cacheItem forKey:key];
            }
        }
        
        return data;
    }
}

- (void) setObject:(id)data forKey:(id)key
{
    if (!key) {
        NSLog(@"ERROR: Cannot store data to (null) key");
        return;
    }
    
    if (!data) {
        [self.cache removeObjectForKey:key];
        return;
    }
    else {
        @synchronized (self.cache) {
            id cacheItem = @{ fUpdatedAt : [NSDate date],
                              @"data" : data };
            
            [self.cache setObject:cacheItem forKey:key];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            NSURL *path = [self.dataPath URLByAppendingPathComponent:[key lastPathComponent]];
            BOOL ret = [data writeToURL:path options:NSDataWritingAtomic error:&error];
            if (!ret) {
                NSLog(@"Failed to write data file:%@", path.absoluteString);
                NSLog(@"ERROR:%@", error.localizedDescription);
                NSLog(@"ERROR:%@", error.localizedRecoverySuggestion);
            }
        });
    }
}

+ (void)synchronize
{
    [[S3File file] writeToCacheFile];
}

- (void) writeToCacheFile
{
    BOOL ret = [self.cache writeToURL:self.cachePath atomically:YES];
    if (!ret) {
        NSLog(@"ERROR: Error writing to S3FILE cache.");
    }
}

- (void) getDataFromFile:(id)filename completedBlock:(S3GetBlock)block progressBlock:(S3ProgressBlock)progress
{
    if (!filename) {
        if (block) {
            block(nil, nil, YES);
        }
        return;
    }

    NSData *data = [self objectForKey:filename];
    if (data) {
        if (block) {
            block(data, nil, YES);
        }
        return;
    }
    else {
        NSString *tempId = [ObjectIdStore randomId];
        NSURL *downloadURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempId]];
        [[NSFileManager defaultManager] removeItemAtURL:downloadURL error:nil];
        
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = [S3File s3bucket];
        downloadRequest.key = filename;
        downloadRequest.downloadingFileURL = downloadURL;
        downloadRequest.downloadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            int rate = (int)(totalBytesSent * 100.0 / totalBytesExpectedToSend);
            if (progress) {
                progress(rate);
            }
        };
        
        AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
        [[transferManager download:downloadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task){
            if (task.error != nil) {
                NSLog(@"%s %@ (%@)","Error downloading :", downloadRequest.key, filename);
                if (block) {
                    block(nil, task.error, NO);
                }
            }
            else {
                NSData *data = [NSData dataWithContentsOfURL:downloadURL];
                [self setObject:data forKey:filename];
                if (block) {
                    block(data, nil, NO);
                }
            }
            [[NSFileManager defaultManager] removeItemAtURL:downloadURL error:nil];
            
            return nil;
        }];
        return;
    }
}

+ (NSString*) saveData:(NSData *)data named:(id)filename extension:(NSString*)extension group:(id)group byUser:(BOOL)byUser completedBlock:(S3PutBlock)block progress:(UIProgressView *)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        progress.progress = 0.0f;
    });
    return [[S3File file] saveData:data named:filename extension:extension group:group byUser:(BOOL)byUser completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = 0.0f;
        });
        if (block) {
            block(file, succeeded, error);
        }
    } progressBlock:^(int percentDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = percentDone / 100.0f;
        });
    }];
}

- (NSString*) longnameFrom:(id)filename extension:(id)extension group:(id)group byUser:(BOOL)byUser
{
    NSString *username = [[User me ] objectId];
    NSString *longname = kStringNull;
    if (![group isEqualToString:kStringNull]) {
        longname = [longname stringByAppendingPathComponent:group];
    }
    if (byUser == YES) {
        longname = [longname stringByAppendingPathComponent:username];
    }
    longname = [longname stringByAppendingPathComponent:[filename stringByAppendingString:extension]];
    
    return longname;
}

+ (NSString*) saveSystemDataInBackground:(NSData *)data named:(id)filename extension:(NSString*)extension
{
    return [[S3File file] saveData:data named:filename extension:extension group:@"System" byUser:NO completedBlock:nil progressBlock:nil];
}

+ (NSString*) saveSystemData:(NSData *)data named:(id)filename extension:(NSString*)extension completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress
{
    return [[S3File file] saveData:data named:filename extension:extension group:@"System" byUser:NO completedBlock:block progressBlock:progress];
}

+ (NSString*) saveData:(NSData *)data named:(id)filename extension:(NSString*)extension group:(id)group byUser:(BOOL)byUser completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress
{
    return [[S3File file] saveData:data named:filename extension:extension group:group byUser:(BOOL)byUser completedBlock:block progressBlock:progress];
}

- (NSString*) saveData:(NSData *)data
                 named:(id)filename
             extension:(NSString*)extension
                 group:(id)group
                byUser:(BOOL)byUser
        completedBlock:(S3PutBlock)block
         progressBlock:(S3ProgressBlock)progress
{
    if (data) {
        if (!filename) {
            filename = [ObjectIdStore newObjectId];
        }
        NSString *longname = [self longnameFrom:filename extension:extension group:group byUser:byUser];
        
        NSString *tempId = [ObjectIdStore randomId];
        NSURL *saveURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:tempId]];
        [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
        BOOL ret = [data writeToURL:saveURL atomically:YES];
        if (ret) {
            [self setObject:data forKey:longname];

            AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
            AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
            uploadRequest.bucket = [S3File s3bucket];
            uploadRequest.key = longname;
            uploadRequest.body = saveURL;
            uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
            uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
                int rate = (int)(totalBytesSent * 100.0 / totalBytesExpectedToSend);
                if (progress) {
                    progress(rate);
                }
            };
            
            [[transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
                if (task.error != nil) {
                    [self setObject:nil forKey:longname];
                    NSLog(@"%s %@","Error uploading :", uploadRequest.key);
                    if (block) {
                        block(nil, NO, task.error);
                    }
                }
                else {
                    [self setObject:data forKey:longname];
                    if (block) {
                        block(longname, YES, nil);
                    }
                }
                [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
                return nil;
            }];
            
            return longname;
        }
        else {
            if (block) {
                block(nil, NO, nil);
            }
            return nil;
        }
    }
    else {
        if (block) {
            block(nil, NO, nil);
        }
        return nil;
    }
}

+ (NSString *)saveImageData:(NSData *)data
{
    return [S3File saveImageData:data completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
}

+ (NSString *)saveMovieData:(NSData *)data
{
    return [S3File saveMovieData:data completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
}

+ (NSString *)saveAudioData:(NSData *)data
{
    return [S3File saveAudioData:data completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    }];
}

+ (NSString *)saveMapImage:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image, kJPEGCompressionMedium);
    return [S3File saveData:data named:nil extension:@".jpg" group:@"MapImage/" byUser:YES completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"ERROR:%@", error.localizedDescription);
        }
    } progressBlock:nil];
}

+ (NSString *)saveImageData:(NSData *)data completedBlock:(S3PutBlock)block
{
    return [S3File saveImageData:data completedBlock:block progressBlock:nil];
}

+ (NSString *)saveMovieData:(NSData *)data completedBlock:(S3PutBlock)block
{
    return [S3File saveMovieData:data completedBlock:block progressBlock:nil];
}

+ (NSString *)saveAudioData:(NSData *)data completedBlock:(S3PutBlock)block
{
    return [S3File saveAudioData:data completedBlock:block progressBlock:nil];
}

+ (NSString *)saveImageData:(NSData *)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress
{
    return [S3File saveData:data named:nil extension:@".jpg" group:@"ProfileMedia/" byUser:YES completedBlock:block progressBlock:progress];
}

+ (NSString *)saveImageData:(NSData *)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress
{
    return [S3File saveData:data named:nil extension:@".jpg" group:@"ProfileMedia/" byUser:YES completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = 0.0f;
        });
        if (block) {
            block(file, succeeded, error);
        }
    } progressBlock:^(int percentDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = percentDone / 100.0f;
        });
    }];
}

+ (NSString *)saveMovieData:(NSData *)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress
{
    return [S3File saveData:data named:nil extension:@".mov" group:@"ProfileMedia/" byUser:YES completedBlock:block progressBlock:progress];
}

+ (NSString *)saveMovieData:(NSData *)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress
{
    return [S3File saveMovieData:data completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = 0.0f;
        });
        if (block) {
            block(file, succeeded, error);
        }
    } progressBlock:^(int percentDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = percentDone / 100.0f;
        });
    }];
}

+ (NSString *)saveAudioData:(NSData *)data completedBlock:(S3PutBlock)block progressBlock:(S3ProgressBlock)progress
{
    return [S3File saveData:data named:nil extension:@".caf" group:@"AudioMedia/" byUser:YES completedBlock:block progressBlock:progress];
}

+ (NSString *)saveAudioData:(NSData *)data completedBlock:(S3PutBlock)block progress:(UIProgressView*)progress
{
    return [S3File saveAudioData:data completedBlock:^(NSString *file, BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = 0.0f;
        });
        if (block) {
            block(file, succeeded, error);
        }
    } progressBlock:^(int percentDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = percentDone / 100.0f;
        });
    }];
}

@end

