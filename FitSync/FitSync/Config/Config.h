//
//  Config.h
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFitbitKlientID     @"227XN8"
#define kFitbitRedirectURI  @"fitsync://fitbit"
#define kFitbitSecret       @"91a8730986b18cfc2c4149fa8874976e"
#define kFitbitApiPrefix    @"https://api.fitbit.com/1/user/-/"

// UserDefaults
extern NSString *const kUserDefaultsSuiteName;
extern NSString *const kUserDefaultsFitbitToken;
extern NSString *const kUserDefaultsFitbitCode;

//Notifications
extern NSString *const kNotificationFitbitDataUpdate;
extern NSString *const kNotificationFitbitTokenChecked;
