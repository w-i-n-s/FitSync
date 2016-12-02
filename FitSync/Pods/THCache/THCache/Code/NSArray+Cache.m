//
//  NSArray+Cache.h
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import "NSArray+Cache.h"
#import "THCacher.h"

@implementation NSArray (Cache)

- (id)initArrayFromCacheWithKey:(NSString *)key {
    self = [self initWithArray:[THCacher restoreItemsFromCacheWithKey:key]];
    return self;
}

- (BOOL)storeArrayToCacheWithKey:(NSString *)key {
    return [THCacher storeItemsToCache:self withKey:key];
}

- (BOOL)removeArrayFromCacheWithKey:(NSString *)key error:(NSError **)err {
    return [THCacher removeItemsFromCacheWithKey:key error:err];
}

@end
