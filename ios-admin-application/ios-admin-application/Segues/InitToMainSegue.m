//
//  initToMainSegue.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "InitToMainSegue.h"
#import "LSWeekView.h"
#import "InitialViewController.h"
#import "UIColor+SimplyBookColors.h"
#import "CalendarViewController.h"
#import "UITraitCollection+SimplyBookLayout.h"

#import "PendingBookingsViewController.h"
#import "DashboardViewController.h"
#import "SettingsViewController.h"

@interface InitToMainSegue () <UIViewControllerTransitioningDelegate>

@end

@implementation InitToMainSegue

- (void)perform
{
    UITabBarController *tabBarController = (UITabBarController *)self.destinationViewController;
    NSAssert([[tabBarController.viewControllers[0] topViewController] isKindOfClass:[CalendarViewController class]],
             @"unexpected navigation structure. %@ expected at tab place 0. %@ occurred.",
             NSStringFromClass([CalendarViewController class]), NSStringFromClass([[tabBarController.viewControllers[0] topViewController] class]));
    ((UIViewController *)tabBarController.viewControllers[0]).tabBarItem.selectedImage = [UIImage imageNamed:@"calendar-tab-active"];
    NSAssert([[tabBarController.viewControllers[1] topViewController] isKindOfClass:[PendingBookingsViewController class]],
             @"unexpected navigation structure. %@ expected at tab place 1. %@ occurred.",
             NSStringFromClass([PendingBookingsViewController class]), NSStringFromClass([[tabBarController.viewControllers[1] topViewController] class]));
    ((UIViewController *)tabBarController.viewControllers[1]).tabBarItem.selectedImage = [UIImage imageNamed:@"pending-tab-active"];
    NSAssert([[tabBarController.viewControllers[2] topViewController] isKindOfClass:[DashboardViewController class]],
             @"unexpected navigation structure. %@ expected at tab place 2. %@ occurred.",
             NSStringFromClass([DashboardViewController class]), NSStringFromClass([[tabBarController.viewControllers[2] topViewController] class]));
    ((UIViewController *)tabBarController.viewControllers[2]).tabBarItem.selectedImage = [UIImage imageNamed:@"dashboard-tab-active"];
    NSAssert([[tabBarController.viewControllers[3] topViewController] isKindOfClass:[SettingsViewController class]],
             @"unexpected navigation structure. %@ expected at tab place 3. %@ occurred.",
             NSStringFromClass([SettingsViewController class]), NSStringFromClass([[tabBarController.viewControllers[3] topViewController] class]));
    ((UIViewController *)tabBarController.viewControllers[3]).tabBarItem.selectedImage = [UIImage imageNamed:@"preferences-tab-active"];
    
    UIViewController *viewController = self.destinationViewController;
    viewController.transitioningDelegate = self;
    [self.sourceViewController presentViewController:self.destinationViewController animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [InitToMainAnimationController new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    InitToMainAnimationController *animationController = [InitToMainAnimationController new];
    animationController.dismiss = YES;
    return animationController;
}

@end

#pragma mark -

@implementation InitToMainAnimationController

- (InitialViewController *)initialController:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self isDismiss]) {
        return (InitialViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    }
    else {
        return (InitialViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    }
}

- (UITabBarController *)tabBarController:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self isDismiss]) {
        return (UITabBarController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    }
    else {
        return (UITabBarController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    }
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return .6;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self isDismiss]) {
        [self animateDismissTransition:transitionContext];
    }
    else {
        [self animatePresentTransition:transitionContext];
    }
}

- (void)animatePresentTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    InitialViewController *initialController = [self initialController:transitionContext];
    UITabBarController *tabBarController = [self tabBarController:transitionContext];
    NSAssert([tabBarController.viewControllers[0] isKindOfClass:[UINavigationController class]], @"unexpected controllers hierarchy");
    NSAssert([[(UINavigationController *)tabBarController.viewControllers[0] topViewController] isKindOfClass:[CalendarViewController class]], @"unexpected controllers hierarchy");
    CalendarViewController *calendarViewController = (CalendarViewController *)[(UINavigationController *)tabBarController.viewControllers[0] topViewController];
    tabBarController.view.frame = initialController.view.frame;
    
    UINavigationController *navController = tabBarController.viewControllers.firstObject;
    CGRect initRect = initialController.view.frame;
    calendarViewController.view.hidden = NO; // preload view
    
    CGFloat height = [LSWeekView preferredHeightForTraitCollection:calendarViewController.traitCollection];
    UIView *navBarLayer = [[UIView alloc] initWithFrame:CGRectMake(0, -height,
                                                                   initRect.size.width, height)];
    navBarLayer.backgroundColor = [UIColor sb_navigationBarColor];
    [initialController.view addSubview:navBarLayer];
    
    UIView *tabBarLayer = [tabBarController.tabBar snapshotViewAfterScreenUpdates:YES];
    tabBarLayer.frame = CGRectMake(-1, initRect.size.height, initRect.size.width + 2, tabBarController.tabBar.bounds.size.height);
    tabBarLayer.layer.borderColor = [UIColor colorWithWhite:.8 alpha:1].CGColor;
    tabBarLayer.layer.borderWidth = .5;
    if ([tabBarController.traitCollection isWideLayout] && tabBarController.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) {
        [initialController.view addSubview:tabBarLayer];
    }
    
    [[transitionContext containerView] addSubview:initialController.view];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                     animations:^{
                         initialController.loginLogoImageView.alpha = 0;
                         initialController.loginLabel.alpha = 0;
                         initialController.view.backgroundColor = navController.topViewController.view.backgroundColor;
                         navBarLayer.center = CGPointMake(navBarLayer.center.x, navBarLayer.center.y + navBarLayer.frame.size.height);
                         tabBarLayer.center = CGPointMake(navBarLayer.center.x, tabBarLayer.center.y - tabBarLayer.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         
                         tabBarController.view.alpha = 0;
                         [[transitionContext containerView] addSubview:tabBarController.view];
                         [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                                          animations:^{
                                              tabBarController.view.alpha = 1.;
                                          }
                                          completion:^(BOOL finished) {
                                              [navBarLayer removeFromSuperview];
                                              [tabBarLayer removeFromSuperview];
                                              [transitionContext completeTransition:YES];
                                          }];
                         
                     }];
}

- (void)animateDismissTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    InitialViewController *initialController = [self initialController:transitionContext];
    UITabBarController *tabBarController = [self tabBarController:transitionContext];
    
    UINavigationController *navController = tabBarController.viewControllers.firstObject;
    CGRect initRect = initialController.view.frame;
    
    CGFloat height = navController.navigationBar.bounds.size.height + 20 + [LSWeekView preferredHeightForTraitCollection:initialController.traitCollection];
    UIView *navBarLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                   initRect.size.width, height)];
    navBarLayer.backgroundColor = [UIColor sb_navigationBarColor];
    [initialController.view addSubview:navBarLayer];
    
    tabBarController.view.frame = initialController.view.frame;
    UIView *tabBarLayer = [tabBarController.tabBar snapshotViewAfterScreenUpdates:YES];
    tabBarLayer.frame = CGRectMake(-1, initRect.size.height - CGRectGetHeight(tabBarController.tabBar.bounds),
                                   initRect.size.width + 2, CGRectGetHeight(tabBarController.tabBar.bounds));
    tabBarLayer.layer.borderColor = [UIColor colorWithWhite:.8 alpha:1].CGColor;
    tabBarLayer.layer.borderWidth = .5;
    [initialController.view addSubview:tabBarLayer];
    
    initialController.loginLogoImageView.alpha = 0;
    initialController.loginLabel.alpha = 0;
    
    [[transitionContext containerView] addSubview:initialController.view];
    [[transitionContext containerView] addSubview:tabBarController.view];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                     animations:^{
                         tabBarController.view.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [tabBarController.view removeFromSuperview];
                         [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                                          animations:^{
                                              initialController.loginLogoImageView.alpha = 1;
                                              initialController.loginLabel.alpha = 1;
                                              initialController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
                                              tabBarLayer.center = CGPointMake(tabBarLayer.center.x, tabBarLayer.center.y + CGRectGetHeight(tabBarLayer.bounds));
                                              navBarLayer.center = CGPointMake(navBarLayer.center.x, navBarLayer.center.y - CGRectGetHeight(navBarLayer.bounds));
                                          }
                                          completion:^(BOOL finished) {
                                              [transitionContext completeTransition:YES];
                                          }];
                     }];
}

@end