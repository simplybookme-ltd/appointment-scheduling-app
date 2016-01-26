//
//  MainToLoginSegue.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "MainToInitSegue.h"
#import "InitToMainSegue.h"
#import "SettingsViewController.h"

@interface MainToInitSegue () <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) UIView *snapshot;

@end

@implementation MainToInitSegue

- (void)perform
{
    UIViewController *source = self.sourceViewController;
    [source setTransitioningDelegate:self];
    [source.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    return;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    InitToMainAnimationController *animationController = [InitToMainAnimationController new];
    animationController.dismiss = YES;
    return animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [InitToMainAnimationController new];
}

@end
