//
//  InitToLoginSegue.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "InitToLoginSegue.h"
#import "InitialViewController.h"
#import "LoginViewController.h"

@interface InitToLoginSegue () <UIViewControllerTransitioningDelegate>

@end

@implementation InitToLoginSegue

- (void)perform
{
    [(UIViewController *)self.destinationViewController setTransitioningDelegate:self];
    [self.sourceViewController presentViewController:self.destinationViewController animated:YES completion:nil];
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

#pragma mark -

@implementation InitToLoginAnimationController

- (InitialViewController *)initialController:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self isDismiss]) {
        return (InitialViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    }
    else {
        return (InitialViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    }
}

- (LoginViewController *)loginController:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self isDismiss]) {
        return (LoginViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    }
    else {
        return (LoginViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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

- (void)prepareSubviewsForAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    InitialViewController *initialController = [self initialController:transitionContext];
    if (!initialController.loginLogoImageView.translatesAutoresizingMaskIntoConstraints) {
        initialController.loginLogoImageView.translatesAutoresizingMaskIntoConstraints = YES;
        initialController.loginLabel.translatesAutoresizingMaskIntoConstraints = YES;
        NSMutableArray *constraintsToRemove = [NSMutableArray array];
        for (NSLayoutConstraint *c in initialController.view.constraints) {
            if (c.firstItem == initialController.loginLogoImageView || c.secondItem == initialController.loginLogoImageView
                || c.firstItem == initialController.loginLabel || c.secondItem == initialController.loginLabel) {
                [constraintsToRemove addObject:c];
            }
        }
        [initialController.view removeConstraints:constraintsToRemove];
    }
}

- (void)animatePresentTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    InitialViewController *initialController = [self initialController:transitionContext];
    LoginViewController *loginController = [self loginController:transitionContext];
    
    [[transitionContext containerView] addSubview:initialController.view];
    loginController.view.alpha = 0;
    [[transitionContext containerView] addSubview:loginController.view];
    
    CGPoint loginLabelCenter = initialController.loginLabel.center;
    CGPoint loginLogoCenter = initialController.loginLogoImageView.center;
    [self prepareSubviewsForAnimation:transitionContext];

    UIImageView *logo = initialController.loginLogoImageView;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                     animations:^{
                         initialController.loginLabel.alpha = 0.;
                         initialController.loginLabel.center = CGPointMake(initialController.loginLabel.center.x, (116-20+8-logo.frame.size.height/2.));
                         logo.frame = CGRectMake(logo.frame.origin.x, (116-20-logo.frame.size.height),
                                                 logo.frame.size.width, logo.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                                          animations:^{
                                              loginController.view.alpha = 1;
                                          }
                                          completion:^(BOOL finished) {
                                              [transitionContext completeTransition:YES];
                                              logo.center = loginLogoCenter;
                                              initialController.loginLabel.center = loginLabelCenter;
                                              initialController.loginLabel.alpha = 1;
                                          }];
                     }];
}

- (void)animateDismissTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    InitialViewController *initialController = [self initialController:transitionContext];
    LoginViewController *loginController = [self loginController:transitionContext];
    [self prepareSubviewsForAnimation:transitionContext];
    UILabel *label = initialController.loginLabel;
    UIImageView *logo = initialController.loginLogoImageView;
    label.alpha = 0.;
    label.center = CGPointMake(label.center.x, (116-20+8-logo.frame.size.height/2.));
    logo.frame = CGRectMake(logo.frame.origin.x, (116-20-logo.frame.size.height),
                                                            logo.frame.size.width, logo.frame.size.height);
    [[transitionContext containerView] addSubview:initialController.view];
    [[transitionContext containerView] addSubview:loginController.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                     animations:^{
                         loginController.view.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:[self transitionDuration:transitionContext] / 2.
                                          animations:^{
                                              logo.center = CGPointMake(initialController.view.frame.size.width / 2.,
                                                                                                        initialController.view.frame.size.height / 2.);
                                              label.alpha = 1;
                                              label.center = CGPointMake(label.center.x,
                                                                         logo.center.y + label.frame.size.height + logo.frame.size.height + 8);
                                          }
                                          completion:^(BOOL finished) {
                                              [transitionContext completeTransition:YES];
                                          }];
                     }];
}

@end