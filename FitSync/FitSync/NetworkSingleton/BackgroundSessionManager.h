//  BackgroundSessionManager.h
//
//  Created by Robert Ryan on 10/11/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

#import "AFHTTPSessionManager.h"

extern NSString * const kBackgroundSessionIdentifier;

@interface BackgroundSessionManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

@end
