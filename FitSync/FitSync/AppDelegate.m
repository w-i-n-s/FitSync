//
//  AppDelegate.m
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import "AppDelegate.h"
#import "Config.h"
#import "NetworkSingleton.h"
@import HealthKit;

@interface AppDelegate ()

@property (strong, nonatomic) NSTimer *twoHoursUpdateTimer;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SharedNetworkSingleton;
    
    if ([HKHealthStore isHealthDataAvailable]) {
        self.healthStore = [[HKHealthStore alloc] init];
    }
    
    self.twoHoursUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:2*60*60 target:self selector:@selector(fireUpdateFromFitBitToHealthKit) userInfo:nil repeats:YES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    self.appInBackgroundMode = YES;
    [SharedNetworkSingleton backgroundSessionManager];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.appInBackgroundMode = NO;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSAssert([[SharedNetworkSingleton backgroundSessionManager].session.configuration.identifier isEqualToString:identifier], @"Identifiers didn't match");
    [SharedNetworkSingleton backgroundSessionManager].savedCompletionHandler = completionHandler;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if ([url.scheme isEqualToString:@"fitsync"]) {
        NSString *urlString = url.absoluteString;
        NSRange range = [urlString rangeOfString:@"code="];
        __block NSString *code = [[urlString substringFromIndex:(range.location +range.length)] stringByReplacingOccurrencesOfString:@"#_=_" withString:@""];
        
        if ([HKHealthStore isHealthDataAvailable]) {
            
            NSSet *dataTypes =
            [NSSet setWithObjects:
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed],
             [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed],
             [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater],
             nil];
            
            [self.healthStore requestAuthorizationToShareTypes:dataTypes readTypes:nil completion:^(BOOL success, NSError *error) {
                if (success) {
                    [SharedNetworkSingleton getTokenUsingAuthCodeString:code completion:nil];
                } else {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Require HealthKit Access" message:@"You didn't allow HealthKit to access these read/write data types." preferredStyle:UIAlertControllerStyleAlert];
                    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
                }
            }];
        }
    }
    
    return NO;
}


#pragma mark - Private

- (void)fireUpdateFromFitBitToHealthKit {
    [SharedNetworkSingleton getAllFitBitDataInBackgroundMode:self.appInBackgroundMode];
}

@end
