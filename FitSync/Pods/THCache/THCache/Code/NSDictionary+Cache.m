//
//  NSDictionary+Cache.m
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import "NSDictionary+Cache.h"
#import "THCacher.h"

@implementation NSDictionary (Cache)

- (id)initDictionaryFromCacheWithKey:(NSString *)key {
    self = [self initWithDictionary:[THCacher restoreItemsFromCacheWithKey:key]];
    return self;
}

- (BOOL)storeDictionaryToCacheWithKey:(NSString *)key {
    return [THCacher storeItemsToCache:self withKey:key];
}

- (BOOL)removeDictionaryFromCacheWithKey:(NSString *)key error:(NSError **)err {
    return [THCacher removeItemsFromCacheWithKey:key error:err];
}

@end
