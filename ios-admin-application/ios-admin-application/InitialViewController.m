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
    if (![[SBSessionManager sharedManager] defaultSession] && ![self restoreSession]) {
        [[SBSessionManager sharedManager] addObserver:self];
        [self performSelector:@selector(showLoginScreen) withObject:nil afterDelay:.4];
    }
    else {
        [self performSegueWithIdentifier:@"mainSegue" sender:nil];
        [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    }
}

- (void)showLoginScreen
{
    [self performSegueWithIdentifier:@"loginSegue" sender:nil];
}

- (BOOL)restoreSession
{
    SBSessionCredentials *credentials = [SBSessionCredentials credentialsFromKeychain:[FXKeychain defaultKeychain]];
    if (credentials) {
        SBSession *session = [SBSession restoreSessionWithCompanyLogin:credentials.companyLogin];
        if (session) {
            [session assignSessionCredentials:credentials];
            [[SBSessionManager sharedManager] setDefaultSession:session];
            return YES;
        }
    }
    return NO;
}

#pragma mark -

- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error
{
    // nothing to do
}

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session
{
    if (![[SBSessionManager sharedManager] defaultSession]) {
        [[SBSessionManager sharedManager] setDefaultSession:session];
        [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    }
}

- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session
{
    // nothing to do
}

- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin
{
    // nothing to do
}

@end
