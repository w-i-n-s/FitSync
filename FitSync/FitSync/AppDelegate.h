//
//  AppDelegate.h
//  FitSync
//
//  Created by Sergey Vinogradov on 08.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HKHealthStore;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HKHealthStore *healthStore;
@property (assign, nonatomic) BOOL appInBackgroundMode;

@end

#define SharedAppDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)
