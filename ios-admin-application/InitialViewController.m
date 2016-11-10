//
//  ViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "InitialViewController.h"
#import "SBSessionManager.h"
#import "AppDelegate.h"
#import "FXKeychain.h"

@interface InitialViewController () <SBSessionManagerDelegateObserver>

@end

@implementation InitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![[SBSessionManager sharedManager] defaultSession]) {
        SBSessionCredentials *credentials = [SBSessionCredentials credentialsFromKeychain:[FXKeychain defaultKeychain]];
        if (credentials) {
            [[SBSessionManager sharedManager] addObserver:self];
            [[SBSessionManager sharedManager] restoreSessionWithCredentials:credentials];
        } else {
            [[SBSessionManager sharedManager] addObserver:self];
            [self performSelector:@selector(showLoginScreen) withObject:nil afterDelay:.4];
        }
    }
    else {
        [[SBSessionManager sharedManager] addObserver:self];
        [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
        [self performSelector:@selector(showMainScreen) withObject:nil afterDelay:.4];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SBSessionManager sharedManager] removeObserver:self];
}

- (void)showLoginScreen
{
    [self performSegueWithIdentifier:@"loginSegue" sender:nil];
}

- (void)showMainScreen
{
    [self performSegueWithIdentifier:@"mainSegue" sender:nil];
}

#pragma mark -

- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"loginSegue" sender:nil];
    });
}

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session
{
    if (![[SBSessionManager sharedManager] defaultSession]) {
        [[SBSessionManager sharedManager] setDefaultSession:session];
    }
    [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"mainSegue" sender:nil];
    });
}

- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session
{
    // nothing to do
}

- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin
{
    // nothing to do
}

- (void)sessionManager:(SBSessionManager *)manager didFailRestoreSessionWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"loginSegue" sender:nil];
    });
}

- (void)sessionManager:(SBSessionManager *)manager didRestoreSession:(SBSession *)session
{
    if (![[SBSessionManager sharedManager] defaultSession]) {
        [[SBSessionManager sharedManager] setDefaultSession:session];
    }
    SBRequest *request = [session getCompanyParam:@"monday_is_first_day" callback:^(SBResponse<id> * _Nonnull response) {
        if (response.result) {
            /// 1 for sunday
            /// 2 for monday
            /// @see -[LSWeekView firstWeekday]
            if ([response.result boolValue]) {
                [session.settings setObject:@(2) forKey:kSBSettingsCalendarFirstWeekdayKey];
            } else {
                [session.settings setObject:@(1) forKey:kSBSettingsCalendarFirstWeekdayKey];
            }
        }
        [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"mainSegue" sender:nil];
        });
    }];
    [session performReqeust:request];
}

@end
