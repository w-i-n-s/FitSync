//
//  NSData+Cache.h
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Cache)

- (id)initDataFromCacheWithKey:(NSString *)key;

- (BOOL)storeDataToCacheWithKey:(NSString *)key;

- (BOOL)removeDataFromCacheWithKey:(NSString *)key error:(NSError **)err;

@end
