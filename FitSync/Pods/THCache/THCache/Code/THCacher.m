//
//  THCacher.m
//  THCache
//
//  Created by Hannes Tribus on 16/02/15.
//  Copyright (c) 2015 3Bus. All rights reserved.
//

#import "THCacher.h"

@implementation THCacher : NSObject 

+ (BOOL)storeItemsToCache:(id)cache withKey:(NSString *)key {
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = cacheDirectories[0];
    NSString* cachePath = [cacheDirectory stringByAppendingPathComponent: key];
    //[cache writeToFile: cachePath atomically: TRUE];
    //TODO crashes when nil objects are passed
    return [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
}

+ (id)restoreItemsFromCacheWithKey:(NSString *)key {
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = cacheDirectories[0];
    NSString* cachePath = [cacheDirectory stringByAppendingPathComponent: key];
    //NSDictionary* cache = [NSDictionary dictionaryWithContentsOfFile: cachePath];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
}

+ (BOOL)removeItemsFromCacheWithKey:(NSString *)key error:(NSError **)err {
    NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = cacheDirectories[0];
    NSString* cachePath = [cacheDirectory stringByAppendingPathComponent: key];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exists = [fm fileExistsAtPath:cachePath];
    if(exists == YES) return [fm removeItemAtPath:cachePath error:err];
    return exists;
}

@end
