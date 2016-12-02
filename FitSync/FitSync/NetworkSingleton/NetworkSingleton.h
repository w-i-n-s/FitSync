//
//  NetworkSingleton.h
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackgroundSessionManager.h"

@interface NetworkSingleton : NSObject

@property (assign, nonatomic) BOOL isCheckTokenDone;
@property (strong, nonatomic) BackgroundSessionManager *backgroundSessionManager;

+ (instancetype)sharedSingleton;

- (void)checkFitBitAuth;
- (void)getAllFitBitDataInBackgroundMode:(BOOL)areWeInBackground;
- (void)getTokenUsingAuthCodeString:(NSString *)authCodeString completion:(void(^) (NSError *error)) completion;
- (void)syncProcessComplete;

@end

#define SharedNetworkSingleton (NetworkSingleton *)[NetworkSingleton sharedSingleton]
