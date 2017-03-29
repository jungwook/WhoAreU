//
//  ObjectIdStore.h
//  WithMe
//
//  Created by 한정욱 on 2016. 7. 20..
//  Copyright © 2016년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjectIdStore : NSObject
+ (BOOL) addObjectId:(id)objectId;
+ (BOOL) containsObjectId:(id)objectId;
+ (NSString *) newObjectId;
+ (NSString *) randomId;
@end
