//
//  NSData+Cache.m
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import "NSData+Cache.h"
#import "THCacher.h"

@implementation NSData (Cache)

- (id)initDataFromCacheWithKey:(NSString *)key {
    self = [self initWithData:[THCacher restoreItemsFromCacheWithKey:key]];
    return self;
}

- (BOOL)storeDataToCacheWithKey:(NSString *)key {
    return [THCacher storeItemsToCache:self withKey:key];
}

- (BOOL)removeDataFromCacheWithKey:(NSString *)key error:(NSError **)err {
    return [THCacher removeItemsFromCacheWithKey:key error:err];
}

@end
