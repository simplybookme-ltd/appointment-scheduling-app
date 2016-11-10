//
//  SimplyBookTabBarController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 22.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SimplyBookTabBarController.h"
#import "SBSessionManager.h"
#import "SBSession.h"
#import "PendingBookingsViewController.h"
#import "SBUser.h"

NS_ENUM(NSInteger, _Tabs) {
    Calendar,
    Upcomming,
    Pending,
    Dashboard,
    Settings
};

@interface SimplyBookTabBarController () <SBSessionManagerDelegateObserver>
{
    SBRequest *getPendingBookingsCountRequest;
    NSUInteger pendingBookingsCount;
    NSTimer *updateTimer;
}
@end

@implementation SimplyBookTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[SBSessionManager sharedManager] addObserver:self];
    
    if ([SBSession defaultSession]) {
        SBUser *user = [SBSession defaultSession].user;
        NSAssert(user != nil, @"no user found");
        if (![user hasAccessToACLRule:SBACLRuleDashboardAccess]) { // warning: check dashboard access before pending bookings access
            NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];
            [controllers removeObjectAtIndex:Dashboard];
            self.viewControllers = controllers;
        }
        if (![user hasAccessToACLRule:SBACLRuleEditBooking] && ![user hasAccessToACLRule:SBACLRuleEditOwnBooking]) {
            NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];
            [controllers removeObjectAtIndex:Pending];
            self.viewControllers = controllers;
        } else {
            [self getPendingBookingsCount];
            [self startUpdateTimer];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingBookingsDidUpdateNotificationHandler:)
                                                         name:kSBPendingBookings_DidUpdateNotification object:nil];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBPendingBookings_DidUpdateNotification
                                                  object:nil];
}

- (void)startUpdateTimer
{
    updateTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(updateTimerHandler:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:updateTimer forMode:NSRunLoopCommonModes];
}

- (void)getPendingBookingsCount
{
    SBSession *session = [SBSession defaultSession];
    NSAssert(session != nil, @"no active session found");
    if (getPendingBookingsCountRequest) {
        [session cancelRequestWithID:getPendingBookingsCountRequest.GUID];
    }
    // can't use getPendingBookingsCount requests because need to filter bookings by performer according to ACL
    getPendingBookingsCountRequest = [[SBSession defaultSession] getPendingBookingsWithCallback:^(SBResponse<NSArray *> * _Nonnull response) {
        if (!response.error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAssert([[self.viewControllers[Pending] topViewController] isKindOfClass:[PendingBookingsViewController class]],
                         @"unexpected navigation structure. %@ expected at tab place 1. %@ occurred.",
                         NSStringFromClass([PendingBookingsViewController class]), NSStringFromClass([[self.viewControllers[Pending] topViewController] class]));
                SBUser *user = [SBSession defaultSession].user;
                NSAssert(user != nil, @"no user found");
                NSInteger count = [response.result count];
                if (![user hasAccessToACLRule:SBACLRuleEditBooking] && [user hasAccessToACLRule:SBACLRuleEditOwnBooking]) {
                    NSIndexSet *indexes = [response.result indexesOfObjectsPassingTest:^BOOL(NSDictionary * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        return [obj[@"unit_group_id"] isEqualToString:user.associatedPerformerID];
                    }];
                    count = indexes.count;
                }
                if (pendingBookingsCount != count) {
                    SBRequest *getPendingBookingsRequest = [session getPendingBookingsWithCallback:nil];
                    [[SBCache cache] invalidateCacheForRequest:getPendingBookingsRequest];
                }
                if (pendingBookingsCount != count) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSBPendingBookings_DidUpdateNotification
                                                                        object:self
                                                                      userInfo:@{kSBPendingBookings_BookingsCountKey: @(count)}];
                }
                [self setPendingBookingsCount:count];
            });
        }
    }];
    getPendingBookingsCountRequest.cachePolicy = SBNoCachePolicy; /// always actual data required
    [session performReqeust:getPendingBookingsCountRequest];
}

- (void)setPendingBookingsCount:(NSUInteger)count
{
    pendingBookingsCount = count;
    if (pendingBookingsCount != 0) {
        if (pendingBookingsCount >= 99) {
            self.viewControllers[Pending].tabBarItem.badgeValue = @"99";
        } else {
            self.viewControllers[Pending].tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)pendingBookingsCount];
        }
    } else {
        self.viewControllers[Pending].tabBarItem.badgeValue = nil;
    }
}

#pragma mark - Handlers

- (void)pendingBookingsDidUpdateNotificationHandler:(NSNotification *)notification
{
    if (notification.object != self) {
        if (notification.userInfo[kSBPendingBookings_BookingsCountKey]) {
            [self setPendingBookingsCount:[notification.userInfo[kSBPendingBookings_BookingsCountKey] unsignedIntegerValue]];
        }
        else {
            [self getPendingBookingsCount];
        }
    }
}

- (void)updateTimerHandler:(NSTimer *)timer
{
    [self getPendingBookingsCount];
}

#pragma mark - SBSessionManager delegate

- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session
{
    if (getPendingBookingsCountRequest) {
        [[SBSession defaultSession] cancelRequestWithID:getPendingBookingsCountRequest.GUID];
    }
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
}

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session
{
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    [self startUpdateTimer];
}

- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin
{
    [[SBSessionManager sharedManager] removeObserver:self];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"mainToLoginSegue" sender:self];
    });
}

- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error
{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
