//
//  NSDictionary+Cache.h
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Cache)

- (id)initDictionaryFromCacheWithKey:(NSString *)key;

- (BOOL)storeDictionaryToCacheWithKey:(NSString *)key;

- (BOOL)removeDictionaryFromCacheWithKey:(NSString *)key error:(NSError **)err;

@end
