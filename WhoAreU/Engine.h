//
//  Engine.h
//  WhoAreU
//
//  Created by 한정욱 on 2017. 4. 21..
//  Copyright © 2017년 SMARTLY CO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Engine : NSObject
+ (PFGeoPoint*) where;
+ (void) initializeSystems;
@end
