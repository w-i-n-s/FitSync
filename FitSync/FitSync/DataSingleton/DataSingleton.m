//
//  DataSingleton.m
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import "DataSingleton.h"
#import "NSDictionary+Cache.h"
#import "Config.h"
#import "AppDelegate.h"
#import "NetworkSingleton.h"
@import HealthKit;

#define kCacheLastSyncDictionaryKey     @"CacheLastSyncDictionaryKey"
#define kCacheTimestampDictionaryKey    @"CacheTimestampDictionaryKey"
#define kCacheSyncObjectsDictionaryKey  @"CacheSyncObjectsDictionaryKey"

#define kSyncPrevDataKey            @"SyncPrevDataKey"
#define kSyncLastDataKey            @"SyncLastDataKey"
#define kSyncStatusKey              @"SyncStatusKey"
#define kSyncStatusValueUnread      @"SyncStatusValueUnread"
#define kSyncStatusValueNeedSync    @"SyncStatusValueNeedSync"

@interface DataSingleton ()

@property (strong, nonatomic) NSMutableDictionary *paramsToSyncDict;
@property (strong, nonatomic) NSMutableDictionary *paramsTimestamp;
@property (strong, nonatomic) NSMutableDictionary <NSString *, NSString*> *paramsLastSyncObjectsId;
@property (strong, nonatomic) NSTimer *syncCountdownTimer;
@property (strong, nonatomic) NSTimer *failsafeSyncCompletionTimer;

@end

@implementation DataSingleton

#pragma mark - Singleton

+ (instancetype)sharedSingleton {
    static DataSingleton *singleton = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[DataSingleton alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    if (self = [super init]) {
        self.paramsToSyncDict = [NSMutableDictionary dictionary];
        self.paramsTimestamp = [NSMutableDictionary dictionaryWithDictionary:[[NSDictionary alloc] initDictionaryFromCacheWithKey:
                                                                              kCacheTimestampDictionaryKey]];
        
        self.paramsLastSyncObjectsId = [NSMutableDictionary dictionaryWithDictionary:[[NSDictionary alloc] initDictionaryFromCacheWithKey:kCacheSyncObjectsDictionaryKey]];
        
        //load values from previous sync
        
        //TODO: Load values from previous sync for "today".
        /*
            - Create a method that appends the date but ignores time etc, like yyyymmdd with NSDateFormatter to you your "kCacheLastSyncDictionaryKey" 
         
            - Should then grab last syncs reletative to today only, then once complete, update the value at that key with the latest data.
         
         */
        
        NSDictionary *lastSyncDict = [[NSDictionary alloc] initDictionaryFromCacheWithKey:kCacheLastSyncDictionaryKey];
        _steps              = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeSteps]] floatValue];
        _restingHeartRate   = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeRestingHeartRate]] floatValue];
        _distance           = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeWalkingRunningDistance]] floatValue];
        _activeCalories     = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeActiveEnergy]] floatValue];
        _restingCalories    = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeRestingEnergy]] floatValue];
        _foodCalories       = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeDietaryEnergy]] floatValue];
        _water              = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeWaterHydration]] floatValue];
        _weight             = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeWeight]] floatValue];
        _fat                = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeBodyFatPercentage]] floatValue];
        _bmi                = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeBodyMassIndex]] floatValue];
        _sleepMinutes       = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeSleepAnalysis]] floatValue];
        _flightsClimbed     = [lastSyncDict[[DataSingleton keyForParameterType:ParameterTypeFlightsClimbed]] floatValue];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkIfAppParamsAreSync];
        });
        
    }
    return self;
}

#pragma mark - Public

- (void)updateValue:(NSNumber *)value forParameterType:(ParameterType)type withDate:(NSDate *)date {
    [self setTimestamp:date forParameterType:type];
    
    //In case of set float to NSInteger we just use standare conversion like (int) automatically
    float floatValue = [value floatValue];
    
    //drop values
    switch (type) {
        case ParameterTypeSteps:
            _steps = floatValue;
            break;
        case ParameterTypeWalkingRunningDistance:
            _distance = floatValue;
            break;
        case ParameterTypeActiveEnergy:
            _activeCalories = floatValue;
            break;
        case ParameterTypeRestingEnergy:
            _restingCalories = floatValue;
            break;
        case ParameterTypeDietaryEnergy:
            _foodCalories = floatValue;
            break;
        case ParameterTypeSleepAnalysis:
            _sleepMinutes = floatValue;
            break;
        case ParameterTypeWeight:
            _weight = floatValue;
            break;
        case ParameterTypeBodyFatPercentage:
            _fat = floatValue;
            break;
        case ParameterTypeBodyMassIndex:
            _bmi = floatValue;
            break;
        case ParameterTypeRestingHeartRate:
            _restingHeartRate = floatValue;
            break;
        case ParameterTypeFlightsClimbed:
            _flightsClimbed = floatValue;
            break;
        case ParameterTypeWaterHydration:
            _water = floatValue;
            break;
    }
    
    [self setSyncCheckerValue:floatValue forParameterType:type];
}

#pragma mark - Custom setters

- (void)setSteps:(NSInteger)steps{
    _steps = steps;
    [self setSyncCheckerValue:steps forParameterType:ParameterTypeSteps];
}

- (void)setRestingHeartRate:(NSInteger)restingHeartRate {
    _restingHeartRate = restingHeartRate;
    [self setSyncCheckerValue:restingHeartRate forParameterType:ParameterTypeRestingHeartRate];
}

- (void)setDistance:(float)distance {
    _distance = distance;
    [self setSyncCheckerValue:distance forParameterType:ParameterTypeWalkingRunningDistance];
}

- (void)setActiveCalories:(NSInteger)activeCalories{
    _activeCalories = activeCalories;
    [self setSyncCheckerValue:activeCalories forParameterType:ParameterTypeActiveEnergy];
}

- (void)setRestingCalories:(NSInteger)restingCalories {
    _restingCalories = restingCalories;
    [self setSyncCheckerValue:restingCalories forParameterType:ParameterTypeRestingEnergy];
}

- (void)setFoodCalories:(NSInteger)foodCalories {
    _foodCalories = foodCalories;
    [self setSyncCheckerValue:foodCalories forParameterType:ParameterTypeDietaryEnergy];
}

- (void)setWater:(NSInteger)water {
    _water = water;
    [self setSyncCheckerValue:water forParameterType:ParameterTypeWaterHydration];
}

- (void)setWeight:(float)weight {
    _weight = weight;
    [self setSyncCheckerValue:weight forParameterType:ParameterTypeWeight];
}

- (void)setFat:(float)fat {
    _fat = fat;
    [self setSyncCheckerValue:fat forParameterType:ParameterTypeBodyFatPercentage];
}

- (void)setBmi:(float)bmi {
    _bmi = bmi;
    [self setSyncCheckerValue:bmi forParameterType:ParameterTypeBodyMassIndex];
}

- (void)setSleepMinutes:(NSInteger)sleepMinutes {
    _sleepMinutes = sleepMinutes;
    [self setSyncCheckerValue:sleepMinutes forParameterType:ParameterTypeSleepAnalysis];
}

- (void)setFlightsClimbed:(NSInteger)flightsClimbed {
    _flightsClimbed = flightsClimbed;
     [self setSyncCheckerValue:flightsClimbed forParameterType:ParameterTypeFlightsClimbed];
}


#pragma mark - Private
#pragma mark Timestamps

// Here we check timestamp. If it outdate than we clean relative value
- (void)setTimestamp:(NSDate *)timestamp forParameterType:(ParameterType)type {
    NSString *key = [DataSingleton keyForParameterType:type];
    NSDate *date = self.paramsTimestamp[key];
    
    if (!date || !timestamp || ([timestamp timeIntervalSinceDate:date]/24/60/60)>0) {
        switch (type) {
            case ParameterTypeSteps:
                _steps = 0;
                break;
            case ParameterTypeWalkingRunningDistance:
                _distance = 0;
                break;
            case ParameterTypeActiveEnergy:
                _activeCalories = 0;
                break;
            case ParameterTypeRestingEnergy:
                _restingCalories = 0;
                break;
            case ParameterTypeDietaryEnergy:
                _foodCalories = 0;
                break;
            case ParameterTypeSleepAnalysis:
                _sleepMinutes = 0;
                break;
            case ParameterTypeWeight:
                _weight = 0;
                break;
            case ParameterTypeBodyFatPercentage:
                _fat = 0;
                break;
            case ParameterTypeBodyMassIndex:
                _bmi = 0;
                break;
            case ParameterTypeRestingHeartRate:
                _restingHeartRate = 0;
                break;
            case ParameterTypeFlightsClimbed:
                _flightsClimbed = 0;
                break;
            case ParameterTypeWaterHydration:
                _water = 0;
                break;
        }
    }
    
    [self.paramsTimestamp setObject:(timestamp ? timestamp : [NSDate date]) forKey:key];
    [self.paramsTimestamp storeDictionaryToCacheWithKey:kCacheTimestampDictionaryKey];
}


#pragma mark Model definition

+ (NSString *)keyForParameterType:(ParameterType)parameterType {
    NSString *result;
    switch (parameterType) {
        case ParameterTypeSteps:
            result = @"Steps";
            break;
        case ParameterTypeWalkingRunningDistance:
            result = @"Walking + Running Distance";
            break;
        case ParameterTypeActiveEnergy:
            result = @"Active Energy";
            break;
        case ParameterTypeRestingEnergy:
            result = @"Resting Energy";
            break;
        case ParameterTypeDietaryEnergy:
            result = @"Dietary Energy (Food Calories)";
            break;
        case ParameterTypeSleepAnalysis:
            result = @"Sleep Analysis";
            break;
        case ParameterTypeWeight:
            result = @"Weight";
            break;
        case ParameterTypeBodyFatPercentage:
            result = @"Body Fat Percentage";
            break;
        case ParameterTypeBodyMassIndex:
            result = @"Body Mass Index (BMI)";
            break;
        case ParameterTypeRestingHeartRate:
            result = @"Resting Heart Rate";
            break;
        case ParameterTypeFlightsClimbed:
            result = @"Flights Climbed";
            break;
        case ParameterTypeWaterHydration:
            result = @"Water / Hydration";
            break;
    }
    
    return result;
}

- (NSDictionary *)dictionaryValue {
    return @{[DataSingleton keyForParameterType:ParameterTypeSteps]                  : @(self.steps),
             [DataSingleton keyForParameterType:ParameterTypeWalkingRunningDistance] : @(self.distance),
             [DataSingleton keyForParameterType:ParameterTypeActiveEnergy]           : @(self.activeCalories),
             [DataSingleton keyForParameterType:ParameterTypeRestingEnergy]          : @(self.restingCalories),
             [DataSingleton keyForParameterType:ParameterTypeDietaryEnergy]          : @(self.foodCalories),
             [DataSingleton keyForParameterType:ParameterTypeSleepAnalysis]          : @(self.sleepMinutes),
             [DataSingleton keyForParameterType:ParameterTypeWeight]                 : @(self.weight),
             [DataSingleton keyForParameterType:ParameterTypeBodyFatPercentage]      : @(self.fat),
             [DataSingleton keyForParameterType:ParameterTypeBodyMassIndex]          : @(self.bmi),
             [DataSingleton keyForParameterType:ParameterTypeRestingHeartRate]       : @(self.restingHeartRate),
             [DataSingleton keyForParameterType:ParameterTypeFlightsClimbed]         : @(self.flightsClimbed),
             [DataSingleton keyForParameterType:ParameterTypeWaterHydration]         : @(self.water)};
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%@; last synced data :\n%@", [super description], [self dictionaryValue]];
}


#pragma mark Countdown timer

- (void)stopCountdownTimer {
    [self.syncCountdownTimer invalidate];
    self.syncCountdownTimer = nil;
}

- (void)startCountdownTimer {
    [self stopCountdownTimer];
    self.syncCountdownTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(syncTimeIsOver) userInfo:nil repeats:NO];
}

- (void)syncTimeIsOver {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *key in self.paramsToSyncDict.allKeys) {
        NSDictionary *dict = self.paramsToSyncDict[key];
        if ([dict[kSyncStatusKey] isEqualToString:kSyncStatusValueNeedSync]) {
            [dictionary setObject:dict forKey:key];
        }//!!!: Here we can check what is go in wrong way with sync
    }
    
    [self.paramsToSyncDict removeAllObjects];
    [self.paramsToSyncDict setDictionary:dictionary];
}

#pragma mark Completeness of sync

- (void)prepareParametersToSyncChecker {
#if DEBUG
    NSLog(@"Start sync");
#endif
    
    [self.failsafeSyncCompletionTimer invalidate];
    self.failsafeSyncCompletionTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:[NetworkSingleton sharedSingleton] selector:@selector(syncProcessComplete) userInfo:nil repeats:NO];
    
    [self.paramsToSyncDict removeAllObjects];
    NSDictionary *dict = [self dictionaryValue];
    for (NSString *key in dict.allKeys) {
        [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:dict[key], kSyncStatusKey:kSyncStatusValueUnread} forKey:key];
    }
    
    [self startCountdownTimer];
}

- (void)setSyncCheckerValue:(float)value forParameterType:(ParameterType)parameterType {
    NSString *key = [DataSingleton keyForParameterType:parameterType];

#if DEBUG
    NSLog(@"sync %@",key);
#endif
    
    NSDictionary *dict = self.paramsToSyncDict[key];
    float prevValue = [dict[kSyncPrevDataKey] floatValue];
    if ((int)prevValue != (int)value) {
        [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(prevValue), kSyncLastDataKey:@(value), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:parameterType]];
    } else {
        [self.paramsToSyncDict removeObjectForKey:key];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFitbitDataUpdate object:nil userInfo:nil];
    [self checkIfAppParamsAreSync];
}

- (void)checkIfAppParamsAreSync {
    for (NSString *key in self.paramsToSyncDict.allKeys) {
        NSDictionary *dict = self.paramsToSyncDict[key];
        if (![dict[kSyncStatusKey] isEqualToString:kSyncStatusValueNeedSync]) {
            return;
        }
    }
    
    [self stopCountdownTimer];
    
    [[self dictionaryValue] storeDictionaryToCacheWithKey:kCacheLastSyncDictionaryKey];
    
    //We can start drop data to HealthKit
#if DEBUG
    NSLog(@"Drop to HealthKit");
#endif
    
    //Test data
    /*
    [self.paramsToSyncDict removeAllObjects];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(12), kSyncLastDataKey:@(14), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeSteps]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(300), kSyncLastDataKey:@(423), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeWalkingRunningDistance]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(0), kSyncLastDataKey:@(675), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeActiveEnergy]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(1200), kSyncLastDataKey:@(1500), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeRestingEnergy]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(200), kSyncLastDataKey:@(950), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeDietaryEnergy]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(4*60*60), kSyncLastDataKey:@(4*60*60), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeSleepAnalysis]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(102), kSyncLastDataKey:@(104.5), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeWeight]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(0.25), kSyncLastDataKey:@(0.23), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeBodyFatPercentage]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(10), kSyncLastDataKey:@(7), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeBodyMassIndex]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(50), kSyncLastDataKey:@(60), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeRestingHeartRate]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(10), kSyncLastDataKey:@(15), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeFlightsClimbed]];
    [self.paramsToSyncDict setObject:@{kSyncPrevDataKey:@(1), kSyncLastDataKey:@(3), kSyncStatusKey:kSyncStatusValueNeedSync} forKey:[DataSingleton keyForParameterType:ParameterTypeWaterHydration]];
     */

    HKHealthStore *healthStore = ((AppDelegate *)[UIApplication sharedApplication].delegate).healthStore;
    NSDate *date = [NSDate date];
    NSDictionary *dict;
    
    //steps
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeSteps]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop steps");
#endif
        }];
    }
    
    //distance
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeWalkingRunningDistance]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit meterUnitWithMetricPrefix:HKMetricPrefixKilo] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop distance");
#endif
        }];
    }
    
    //active calories/energy
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeActiveEnergy]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop active calories/energy");
#endif
        }];
    }
    
    //rest calories/energy
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeRestingEnergy]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop rest calories/energy");
#endif
        }];
    }
    
    //dietary calories/energy
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeDietaryEnergy]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop dietary calories/energy");
#endif
        }];
    }
    
    //sleep analysis
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeSleepAnalysis]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKCategorySample *sample = [HKCategorySample categorySampleWithType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]
                                                                      value:HKCategoryValueSleepAnalysisInBed
                                                                  startDate:[date dateByAddingTimeInterval:-value]
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop sleep analysis");
#endif
        }];
    }

    //weight
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeWeight]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop weight");
#endif
        }];
    }
    
    //fat
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeBodyFatPercentage]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit percentUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop fat");
#endif
        }];
    }
    
    //bmi
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeBodyMassIndex]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop bmi");
#endif
        }];
    }

    //heartrate
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeRestingHeartRate]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]
                                                                   quantity:[HKQuantity quantityWithUnit:[[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop heartrate");
#endif
        }];
    }
    
    //flights climbed
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeFlightsClimbed]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop flights climbed");
#endif
        }];
    }
    //water
    dict = self.paramsToSyncDict[[DataSingleton keyForParameterType:ParameterTypeWaterHydration]];
    if (dict) {
        double value = [dict[kSyncLastDataKey] integerValue] - [dict[kSyncPrevDataKey] integerValue];
        HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit literUnitWithMetricPrefix:HKMetricPrefixMilli] doubleValue:value]
                                                                  startDate:date
                                                                    endDate:date];
        [healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"drop water");
#endif
        }];
    }
    
    [self.failsafeSyncCompletionTimer invalidate];
    self.failsafeSyncCompletionTimer = nil;
    
    [SharedNetworkSingleton performSelector:@selector(syncProcessComplete) withObject:nil afterDelay:0.5];
}

@end
