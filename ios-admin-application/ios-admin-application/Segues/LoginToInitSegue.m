//
//  LoginToMainSegue.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "LoginToInitSegue.h"
#import "InitToLoginSegue.h"

@interface LoginToInitSegue () <UIViewControllerTransitioningDelegate>

@end

@implementation LoginToInitSegue

- (void)perform
{
    [(UIViewController *)self.sourceViewController setTransitioningDelegate:self];
    [self.sourceViewController dismissViewControllerAnimated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [InitToLoginAnimationController new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    InitToLoginAnimationController *animationController = [InitToLoginAnimationController new];
    animationController.dismiss = YES;
    return animationController;
}

@end
