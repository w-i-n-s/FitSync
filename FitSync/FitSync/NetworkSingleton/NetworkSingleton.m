//
//  NetworkSingleton.m
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import "NetworkSingleton.h"
#import "Config.h"
#import "AFNetworking.h"
#import "AFOAuth2Manager.h"
#import "DataSingleton.h"
#import "AppDelegate.h"

@interface NetworkSingleton ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;
@property (assign, nonatomic) BOOL getAllDataProcessActive;

@end

@implementation NetworkSingleton

#pragma mark - Singleton

+ (instancetype)sharedSingleton {
    static NetworkSingleton *singleton = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[NetworkSingleton alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    if (self = [super init]) {
        
        //no token
        if (![self fitbitToken]) {
            self.isCheckTokenDone = YES;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //TODO: Reachability
            [self startLogic];
        });
    }
    return self;
}

- (void)startLogic {
    //check if token expired with ask the profile
    if ([self fitbitToken]) {
        self.isCheckTokenDone = NO;
        
        [self getDataFromFitbitUsingRequestSuffixString:@"profile.json" completion:^(NSDictionary *responseObject) {
            //TODO:grab all measurement units
            /*
            {
                user =     {
                    age = 33;
                    avatar = "https://d6y8zfzc2qfsl.cloudfront.net/208E1775-66BD-0868-1153-0B657B7BD3AC_profile_100_square.png";
                    avatar150 = "https://d6y8zfzc2qfsl.cloudfront.net/208E1775-66BD-0868-1153-0B657B7BD3AC_profile_150_square.png";
                    averageDailySteps = 0;
                    clockTimeDisplayFormat = 24hour;
                    corporate = 0;
                    corporateAdmin = 0;
                    country = BG;
                    dateOfBirth = "1983-01-15";
                    displayName = "\U0421\U0435\U0440\U0433\U0435\U0439";
                    displayNameSetting = name;
                    distanceUnit = METRIC;
                    encodedId = 52VCT8;
                    features =         {
                        exerciseGoal = 1;
                    };
                    foodsLocale = "en_US";
                    fullName = "\U0421\U0435\U0440\U0433\U0435\U0439 \U0412\U0438\U043d\U043e\U0433\U0440\U0430\U0434\U043e\U0432";
                    gender = MALE;
                    glucoseUnit = METRIC;
                    height = 190;
                    heightUnit = METRIC;
                    locale = "en_EU";
                    memberSince = "2016-11-07";
                    mfaEnabled = 0;
                    offsetFromUTCMillis = "-28800000";
                    startDayOfWeek = MONDAY;
                    strideLengthRunning = "108.2";
                    strideLengthRunningType = default;
                    strideLengthWalking = "78.90000000000001";
                    strideLengthWalkingType = default;
                    swimUnit = METRIC;
                    timezone = "America/Los_Angeles";
                    topBadges =         (
                    );
                    waterUnit = METRIC;
                    waterUnitName = ml;
                    weight = 103;
                    weightUnit = METRIC;
                };
            }
            */
        }];
    }
}


#pragma mark - Private

- (NSString *)fitbitToken {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
    return [userDefaults objectForKey:kUserDefaultsFitbitToken];
}

- (BackgroundSessionManager *)backgroundSessionManager {
    if (!_backgroundSessionManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
        _backgroundSessionManager = [[BackgroundSessionManager alloc] initWithSessionConfiguration:configuration];
        [_backgroundSessionManager setResponseSerializer:[AFJSONResponseSerializer serializer]];
        [_backgroundSessionManager.requestSerializer setValue:[@"Bearer " stringByAppendingString:[self fitbitToken]?[self fitbitToken]:@""] forHTTPHeaderField:@"Authorization"];
    }
    
    return _backgroundSessionManager;
}

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        [_sessionManager setResponseSerializer:[AFJSONResponseSerializer serializer]];
        [_sessionManager.requestSerializer setValue:[@"Bearer " stringByAppendingString:[self fitbitToken]?[self fitbitToken]:@""] forHTTPHeaderField:@"Authorization"];
    }
    
    return [SharedAppDelegate appInBackgroundMode] ? self.backgroundSessionManager : _sessionManager;
}

- (void)getDataFromFitbitUsingRequestSuffixString:(NSString *)suffixString completion:(void(^) (NSDictionary *responseObject)) completion{
    
    NSString *urlString = [kFitbitApiPrefix stringByAppendingString:suffixString];
    
    [[self sessionManager] GET:urlString parameters:nil progress:nil success:^(NSURLSessionTask *task, NSDictionary * responseObject) {
        if (!self.isCheckTokenDone) {
            self.isCheckTokenDone = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFitbitTokenChecked object:nil userInfo:nil];
        }
        
        if (completion) {
            completion(responseObject);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSDictionary *dict = nil;
        if (error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]) {
            dict = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:NSJSONReadingMutableContainers error:nil];
        }
#ifdef DEBUG
        NSLog(@"error %@\n%@",error,dict);
#endif
        if ([dict[@"errors"][0][@"errorType"] isEqualToString:@"expired_token"]) {
            [self renewFitBitToken];
        } else if ([dict[@"errors"][0][@"errorType"] isEqualToString:@"invalid_token"]){
            NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
            NSString *code = [userDefaults objectForKey:kUserDefaultsFitbitCode];
            [self cleanFitBitToken];
            
            if (code) {
                [self getTokenUsingAuthCodeString:code completion:^(NSError *error) {
                    [self getAllFitBitDataInBackgroundMode:[SharedAppDelegate appInBackgroundMode]];
                }];
            }
        } else {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (NSDate *)dateFromFitbitDateString:(NSString *)dateString {
    if (!dateString) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return [dateFormatter dateFromString:dateString];
}

#pragma mark - Public

- (void)checkFitBitAuth {
    if (![self fitbitToken]) {
        //full scope from https://dev.fitbit.com/docs/oauth2/
        //activity%20heartrate%20location%20nutrition%20profile%20settings%20sleep%20social%20weight
        
        NSString *urlString = [NSString stringWithFormat:@"https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=%@&redirect_uri=%@&scope=activity+nutrition+heartrate+location+nutrition+profile+settings+sleep+social+weight&expires_in=2592000",kFitbitKlientID,kFitbitRedirectURI];
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];//URLFragmentAllowedCharacterSet
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)getAllFitBitDataInBackgroundMode:(BOOL)areWeInBackground {
    if ([self fitbitToken]) {
        
        if (self.getAllDataProcessActive) {
#if DEBUG
            NSLog(@"Sync process already start");
#endif
            
            return;
        }
        
        self.getAllDataProcessActive = YES;
        
        [SharedDataSingleton prepareParametersToSyncChecker];
        
        [self getActivity];
        [self getRestingHeartRate];
        [self getWeightFatBmi];
        [self getFoodCalories];
        [self getHydration];
        [self getBedTime];
    } else {
        if (!areWeInBackground) {
            [self checkFitBitAuth];
        }
    }
}

- (void)syncProcessComplete {
#if DEBUG
    NSLog(@"Stop sync");
#endif
    
    self.getAllDataProcessActive = NO;
}


#pragma mark Auth

- (void)getTokenUsingAuthCodeString:(NSString *)authCodeString completion:(void(^) (NSError *error)) completion{
    NSURL *baseURL = [NSURL URLWithString:@"https://www.fitbit.com/oauth2/authorize"];
    
    AFOAuth2Manager *OAuth2Manager = [AFOAuth2Manager managerWithBaseURL:baseURL clientID:kFitbitKlientID secret:kFitbitSecret];
    OAuth2Manager.responseSerializer.acceptableContentTypes = [OAuth2Manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    NSDictionary *dict = @{@"client_id":kFitbitKlientID, @"grant_type":@"authorization_code",@"redirect_uri":kFitbitRedirectURI,@"code":authCodeString};
    
    __weak __typeof(self)weakSelf = self;
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"https://api.fitbit.com/oauth2/token" parameters:dict success:^(AFOAuthCredential *credential) {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
        [userDefaults setObject:credential.accessToken forKey:kUserDefaultsFitbitToken];
        [userDefaults setObject:authCodeString forKey:kUserDefaultsFitbitCode];
        [userDefaults synchronize];
        
        self.isCheckTokenDone = YES;
        _sessionManager = nil;
        _backgroundSessionManager = nil;
        
        [weakSelf getAllFitBitDataInBackgroundMode:NO];
        
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        //NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:NSJSONReadingMutableContainers error:nil];
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void)cleanFitBitToken {
    self.isCheckTokenDone = NO;
    _sessionManager = nil;
    _backgroundSessionManager = nil;
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsSuiteName];
    [userDefaults removeObjectForKey:kUserDefaultsFitbitToken];
    [userDefaults synchronize];
}

- (void)renewFitBitToken {
    [self cleanFitBitToken];
    
    //TODO: renew token
    /*curl -X POST -i -H "Authorization: Basic MjI3WE44OjkxYTg3MzA5ODZiMThjZmMyYzQxNDlmYTg4NzQ5NzZl" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=refresh_token" -d "refresh_token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1MlZDVDgiLCJhdWQiOiIyMjdYTjgiLCJpc3MiOiJGaXRiaXQiLCJ0eXAiOiJhY2Nlc3NfdG9rZW4iLCJzY29wZXMiOiJyc29jIHJhY3QgcnNldCBybG9jIHJ3ZWkgcmhyIHJudXQgcnBybyByc2xlIiwiZXhwIjoxNDc4ODI5Mjc0LCJpYXQiOjE0Nzg4MDA0NzR9.nUMJQrHorJHTD_QbD1Q_VGkiEMl672bWsSxbBeC60e8" https://api.fitbit.com/oauth2/token
     */
}


#pragma mark Data getters

- (void)getActivity {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    NSString *urlSuffixString = [NSString stringWithFormat:@"activities/date/%@.json", [formatter stringFromDate:[NSDate date]]];
    [self getDataFromFitbitUsingRequestSuffixString:urlSuffixString completion:^(NSDictionary *responseObject) {
        NSDictionary *summary = responseObject[@"summary"];
        
        NSDate *date = [NSDate date];
        //steps
        [SharedDataSingleton updateValue:@([summary[@"steps"] integerValue]) forParameterType:ParameterTypeSteps withDate:date];
        
        //!!!:alternative distance
        /*
        NSArray *distances = summary[@"distances"];
        float totalDistance = 0;
        for (NSDictionary *dict in distances) {
            if (![dict[@"activity"] isEqualToString:@"loggedActivities"] &&
                ![dict[@"activity"] isEqualToString:@"tracker"] &&
                ![dict[@"activity"] isEqualToString:@"total"] &&
                ![dict[@"activity"] isEqualToString:@"veryActive"] &&
                ![dict[@"activity"] isEqualToString:@"moderatelyActive"] &&
                ![dict[@"activity"] isEqualToString:@"lightlyActive"] &&
                ![dict[@"activity"] isEqualToString:@"sedentaryActive"]) {
                totalDistance += [dict[@"distance"] floatValue];
            }
        }
         */
        
        //distance
        NSArray *activities = responseObject[@"activities"];
        NSInteger calories = 0;
        float totalDistance = 0;
        for (NSDictionary *dict in activities) {
            calories += [dict[@"calories"] integerValue];
            totalDistance += [dict[@"distance"] floatValue];
        }
        
        [SharedDataSingleton updateValue:@(totalDistance) forParameterType:ParameterTypeWalkingRunningDistance withDate:date];
        
        //Active Energy
        [SharedDataSingleton updateValue:@(calories) forParameterType:ParameterTypeActiveEnergy withDate:date];
        
        //Resting Energy
        [SharedDataSingleton updateValue:@([summary[@"caloriesBMR"] integerValue]) forParameterType:ParameterTypeRestingEnergy withDate:date];
        
        //Floors climbed. It only available for users with compatible trackers.
        [SharedDataSingleton updateValue:@([summary[@"floors"] integerValue]) forParameterType:ParameterTypeFlightsClimbed withDate:date];
    }];
}

- (void)getRestingHeartRate {
    [self getDataFromFitbitUsingRequestSuffixString:@"activities/heart/date/today/1d.json" completion:^(NSDictionary *responseObject) {
        NSDate *date = [self dateFromFitbitDateString:responseObject[@"activities-heart"][0][@"dateTime"]];
        [SharedDataSingleton updateValue:@([responseObject[@"activities-heart"][0][@"value"][@"restingHeartRate"] integerValue]) forParameterType:ParameterTypeRestingHeartRate withDate:date];
    }];
}

- (void)getWeightFatBmi {
    for (NSString *option in @[@"weight", @"fat", @"bmi"]) {
        NSString *urlSuffixString = [NSString stringWithFormat:@"body/%@/date/today/1d.json", option];
        [self getDataFromFitbitUsingRequestSuffixString:urlSuffixString completion:^(NSDictionary *responseObject) {
            if (responseObject[@"body-weight"]) {//Weight
                NSDate *date = [self dateFromFitbitDateString:responseObject[@"body-weight"][0][@"dateTime"]];
                [SharedDataSingleton updateValue:@([responseObject[@"body-weight"][0][@"value"] floatValue]) forParameterType:ParameterTypeWeight withDate:date];
            } else if (responseObject[@"body-bmi"]) {//Body Mass Index (BMI)
                NSDate *date = [self dateFromFitbitDateString:responseObject[@"body-bmi"][0][@"dateTime"]];
                [SharedDataSingleton updateValue:@([responseObject[@"body-bmi"][0][@"value"] floatValue]) forParameterType:ParameterTypeBodyMassIndex withDate:date];
            } else if (responseObject[@"body-fat"]) {//Body Fat Percentage
                NSDate *date = [self dateFromFitbitDateString:responseObject[@"body-fat"][0][@"dateTime"]];
                [SharedDataSingleton updateValue:@([responseObject[@"body-fat"][0][@"value"] floatValue]/100) forParameterType:ParameterTypeBodyFatPercentage withDate:date];
            }
        }];
    }
}

- (void)getFoodCalories {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    NSString *urlSuffixString = [NSString stringWithFormat:@"foods/log/date/%@.json", [formatter stringFromDate:[NSDate date]]];
    [self getDataFromFitbitUsingRequestSuffixString:urlSuffixString completion:^(NSDictionary *responseObject) {
        NSDate *date = [NSDate date];
        [SharedDataSingleton updateValue:@([responseObject[@"summary"][@"calories"] integerValue]) forParameterType:ParameterTypeDietaryEnergy withDate:date];
    }];
}

- (void)getHydration {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    NSString *urlSuffixString = [NSString stringWithFormat:@"foods/log/water/date/%@.json", [formatter stringFromDate:[NSDate date]]];
    [self getDataFromFitbitUsingRequestSuffixString:urlSuffixString completion:^(NSDictionary *responseObject) {
        NSDate *date = [NSDate date];
        [SharedDataSingleton updateValue:@([responseObject[@"summary"][@"water"] integerValue]) forParameterType:ParameterTypeWaterHydration withDate:date];
    }];
}

- (void)getBedTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";

    NSString *urlSuffixString = [NSString stringWithFormat:@"sleep/date/%@.json", [formatter stringFromDate:[NSDate date]]];
    [self getDataFromFitbitUsingRequestSuffixString:urlSuffixString completion:^(NSDictionary *responseObject) {
        NSDate *date = [NSDate date];
        [SharedDataSingleton updateValue:@([responseObject[@"summary"][@"totalTimeInBed"] integerValue]) forParameterType:ParameterTypeSleepAnalysis withDate:date];
    }];
}

@end
