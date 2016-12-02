//
//  DataSingleton.h
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,ParameterType) {
    ParameterTypeSteps,
    ParameterTypeWalkingRunningDistance,
    ParameterTypeActiveEnergy,
    ParameterTypeRestingEnergy,
    ParameterTypeDietaryEnergy,
    ParameterTypeSleepAnalysis,
    ParameterTypeWeight,
    ParameterTypeBodyFatPercentage,
    ParameterTypeBodyMassIndex,
    ParameterTypeRestingHeartRate,
    ParameterTypeFlightsClimbed,
    ParameterTypeWaterHydration
};

@interface DataSingleton : NSObject

@property (assign, nonatomic) NSInteger steps;
@property (assign, nonatomic) NSInteger restingHeartRate;
@property (assign, nonatomic) float     distance;
@property (assign, nonatomic) NSInteger activeCalories;
@property (assign, nonatomic) NSInteger restingCalories;
@property (assign, nonatomic) NSInteger foodCalories;
@property (assign, nonatomic) NSInteger water;
@property (assign, nonatomic) float     weight;
@property (assign, nonatomic) float     fat;
@property (assign, nonatomic) float     bmi;
@property (assign, nonatomic) NSInteger sleepMinutes;
@property (assign, nonatomic) NSInteger flightsClimbed;

+ (instancetype)sharedSingleton;
- (void)prepareParametersToSyncChecker;
- (void)updateValue:(NSNumber *)value forParameterType:(ParameterType)type withDate:(NSDate *)date;

@end

#define SharedDataSingleton (DataSingleton *)[DataSingleton sharedSingleton]
