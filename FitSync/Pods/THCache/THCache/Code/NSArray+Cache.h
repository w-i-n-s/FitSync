//
//  NSArray+Cache.h
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Cache)

- (id)initArrayFromCacheWithKey:(NSString *)key;

- (BOOL)storeArrayToCacheWithKey:(NSString *)key;

- (BOOL)removeArrayFromCacheWithKey:(NSString *)key error:(NSError **)err;

@end
