//
//  ObjectIdStore.m
//  WithMe
//
//  Created by 한정욱 on 2016. 7. 20..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import "ObjectIdStore.h"

#define OBJECTIDSTORE @"ObjectIdStore"
#define SYSTEM_PATH_COMPONENT @"Engine"
#define SYSTEM_MEDIA_CACHE @"MediaCache"

@interface ObjectIdStore()
@property (nonatomic, strong) NSMutableSet *objectIdSet;
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic, strong) NSURL *systemPath;
@end

@implementation ObjectIdStore

+ (instancetype) new
{
    static id sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[self alloc] initOnce];
    });
    return sharedFile;
}

- (instancetype)initOnce
{
    self = [super init];
    if (self) {
        self.systemPath = [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:SYSTEM_PATH_COMPONENT] URLByAppendingPathComponent:OBJECTIDSTORE];
        self.objectIdSet = [NSMutableSet setWithArray:[NSArray arrayWithContentsOfURL:self.systemPath]];
        self.lock = [NSObject new]; //MUTEX LOCK
    }
    return self;
}

+ (BOOL) addObjectId:(id)objectId
{
    ObjectIdStore *store = [ObjectIdStore new];
    return [store addObjectId:objectId];
}

+ (NSString*) randomId
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


- (BOOL) addObjectId:(id)objectId
{
    @synchronized (self.lock) {
        [self.objectIdSet addObject:objectId];
        return [[self.objectIdSet allObjects] writeToURL:self.systemPath atomically:YES];
    }
}

+ (BOOL) containsObjectId:(id)objectId
{
    ObjectIdStore *store = [ObjectIdStore new];
    return [store containsObjectId:objectId];
}

- (BOOL) containsObjectId:(id)objectId
{
    return [self.objectIdSet containsObject:objectId];
}

+ (NSString *) newObjectId
{
    ObjectIdStore *store = [ObjectIdStore new];
    @synchronized (store.lock) {
        NSString *randId = @"";
        do {
            randId = [ObjectIdStore randomId];
        } while ([ObjectIdStore containsObjectId:randId]);
        [ObjectIdStore addObjectId:randId];
        
        return randId;
    }
}

@end

