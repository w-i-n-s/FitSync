//
//  THCacher.h
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THCacher : NSObject

+ (BOOL)storeItemsToCache:(id)cache withKey:(NSString *)key;

+ (id)restoreItemsFromCacheWithKey:(NSString *)key;

+ (BOOL)removeItemsFromCacheWithKey:(NSString *)key error:(NSError **)err;

@end
