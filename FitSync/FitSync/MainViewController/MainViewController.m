//
//  MainViewController.m
//  FitSync
//
//  Created by Sergey Vinogradov on 09.11.16.
//  Copyright © 2016 https://github.com/w-i-n-s/FitSync. All rights reserved.
//

#import "MainViewController.h"
#import "DataSingleton.h"
#import "NetworkSingleton.h"
#import "Config.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *syncButton;
@property (strong, nonatomic) NSArray *itemslist;
@property (assign, nonatomic) BOOL dataIsUpdated;

@property (weak, nonatomic) IBOutlet UIView *hoverView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconViewWidthConstraints;

@end

@implementation MainViewController

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.itemslist = @[@"Steps", @"Distance", @"Active Energy", @"Resting Energy", @"Food Calories", @"Sleep Analysis", @"Weight", @"Body Fat Percentage", @"Body Mass Index (BMI)", @"Resting Heart Rate", @"Flights Climbed", @"Water / Hydration"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self shartHoverAnimation];
    
    [self resetView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:kNotificationFitbitDataUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:kNotificationFitbitTokenChecked object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kNotificationFitbitDataUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationFitbitTokenChecked object:nil];
}


#pragma mark - Actions

- (IBAction)tapSyncButton:(id)sender {
    [SharedNetworkSingleton getAllFitBitDataInBackgroundMode:NO];
    self.dataIsUpdated = YES;
}

#pragma mark - Private

- (void)shartHoverAnimation {
    if (self.hoverView.hidden) {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    weakSelf.iconViewWidthConstraints.constant = weakSelf.syncButton.frame.size.width;
    [UIView animateWithDuration:0.5 animations:^{
        [weakSelf.hoverView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.iconView.frame = weakSelf.syncButton.frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.hoverView.alpha = 0.0;
            } completion:^(BOOL finished) {
                weakSelf.hoverView.hidden = YES;
            }];
        }];
    }];
}

- (void)resetView {
    self.syncButton.enabled = [SharedNetworkSingleton isCheckTokenDone];
}

- (NSString *)stringValueForRow:(NSInteger)row {
    NSString *result = @"";
    switch (row) {
        case 0://Steps
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton steps]];
            break;
        case 1://Distance
            result = [NSString stringWithFormat:@"%.1f",[SharedDataSingleton distance]];
            break;
        case 2://Active Energy
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton activeCalories]];
            break;
        case 3://Resting Energy
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton restingCalories]];
            break;
        case 4://Food Calories
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton foodCalories]];
            break;
        case 5://Sleep Analysis
            result = [NSString stringWithFormat:@"%lim",(long)[SharedDataSingleton sleepMinutes]];
            break;
        case 6://Weight
            result = [NSString stringWithFormat:@"%.1f",[SharedDataSingleton weight]];
            break;
        case 7://Body Fat Percentage
            result = [[NSString stringWithFormat:@"%.2f",[SharedDataSingleton fat]*100] stringByAppendingString:@"%"];
            break;
        case 8://Body Mass Index (BMI)
            result = [NSString stringWithFormat:@"%.2f",[SharedDataSingleton bmi]];
            break;
        case 9://Resting Heart Rate
            result = [NSString stringWithFormat:@"%li per min.",(long)[SharedDataSingleton restingHeartRate]];
            break;
        case 10://Flights Climbed
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton flightsClimbed]];
            break;
        case 11://Water / Hydration
            result = [NSString stringWithFormat:@"%li",(long)[SharedDataSingleton water]];
            break;
    }
    
    return result;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.itemslist count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    cell.textLabel.text = self.itemslist[indexPath.row];
    
    if (self.dataIsUpdated) {
        cell.detailTextLabel.text = [self stringValueForRow:indexPath.row];
    }
    
    return cell;
}



@end
