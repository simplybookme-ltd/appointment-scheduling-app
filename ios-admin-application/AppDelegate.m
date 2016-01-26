//
//  AppDelegate.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "AppDelegate.h"
#import "SBSessionManager.h"
#import "UIColor+SimplyBookColors.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UINavigationBar appearance] setBarTintColor:[UIColor sb_navigationBarColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UITabBar appearance] setTintColor:[UIColor sb_tintColor]];
    [[UIActivityIndicatorView appearance] setColor:[UIColor sb_tintColor]];
    [[UIRefreshControl appearance] setTintColor:[UIColor sb_tintColor]];
    [[UIView appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:[UIColor whiteColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (userInfo[@"aps"][@"alert"] && application.applicationState != UIApplicationStateActive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveRemoteNotification
                                                            object:[UIApplication sharedApplication]
                                                          userInfo:userInfo];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)_deviceToken
{
    NSString *deviceToken = [[[_deviceToken description]
                              stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                             stringByReplacingOccurrencesOfString:@" " withString:@""];
    SBSession *session = [SBSession defaultSession];
    [session.settings setObject:deviceToken forKey:kSBSettingsDeviceTokenKey];
    [session.settings setObject:@YES forKey:kSBSettingsNotificationsEnabledKey];
    SBRequest *request = [session addDeviceToken:deviceToken callback:^(SBResponse *response) {
        if (response.error) {
            [[SBSession defaultSession].settings setObject:@NO forKey:kSBSettingsNotificationsEnabledKey];
        }
    }];
    [session performReqeust:request];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    SBSession *session = [SBSession defaultSession];
    [session.settings setObject:nil forKey:kSBSettingsDeviceTokenKey];
    [session.settings setObject:@NO forKey:kSBSettingsNotificationsEnabledKey];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -

- (void)registerForRemoteNotifications
{
    if ([[SBSessionManager sharedManager] defaultSession]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert
                                                                                                              categories:nil]];
    }
}

@end
