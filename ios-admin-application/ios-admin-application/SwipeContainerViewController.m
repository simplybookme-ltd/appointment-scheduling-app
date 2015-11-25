//
//  SwipeContainerViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SwipeContainerViewController.h"

NSString * const _Nonnull kSwipeContainerViewControllerInitialSegueIdentifier = @"SwipeContainer-embed";

@interface SwipeViewsStoryboardSegue ()

@property (nonatomic, strong, nonnull) SwipeContainerViewController *container;

@end

@interface SwipeContainerViewController ()

@property (nonatomic) SwipeViewsDirection direction;

@end

#pragma mark -

@implementation SwipeContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self performSegueWithIdentifier:kSwipeContainerViewControllerInitialSegueIdentifier sender:self
                      swipeDirection:SwipeViewsNoDirection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


#pragma mark - Navigation

- (void)performSegueWithIdentifier:(nonnull NSString *)identifier sender:(nullable id)sender
                    swipeDirection:(SwipeViewsDirection)direction
{
    NSParameterAssert(identifier != nil);
    self.direction = direction;
    [self performSegueWithIdentifier:identifier sender:sender];
}

- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender
{
    NSParameterAssert(segue != nil);
    if ([segue isKindOfClass:[SwipeViewsStoryboardSegue class]]) {
        if (self.delegate) {
            [self.delegate swipeContainer:self willSwipeToViewController:segue.destinationViewController];
        }
        [self addChildViewController:segue.destinationViewController];
        SwipeViewsStoryboardSegue *swipeSegue = (SwipeViewsStoryboardSegue *)segue;
        swipeSegue.direction = self.direction;
        swipeSegue.container = self;
    }
}

@end

#pragma mark -

@implementation SwipeViewsStoryboardSegue

- (void)perform
{
    NSAssert(self.container != nil, @"can't perform segue if no container specified");

    UIView *sourceView = nil;
    if (self.container.embeddedViewController) {
        sourceView = self.container.embeddedViewController.view;
    }
    else {
        self.direction = SwipeViewsNoDirection;
    }
    UIView *destinationView = self.destinationViewController.view;

    [self.destinationViewController willMoveToParentViewController:self.container];
    [self.container addChildViewController:self.destinationViewController];
    switch (self.direction) {
        case SwipeViewsNoDirection:
            destinationView.frame = CGRectMakeFromPointSize(CGPointZero, self.container.view.frame.size);
            [self.container.view addSubview:destinationView];
            [self finishTransaction];
            break;
        case SwipeViewsLeftToRightDirection:
            [self moveDestinationView:destinationView leftToRightSourceView:sourceView];
            break;
        case SwipeViewsRightToLeftDirection:
            [self moveDestinationView:destinationView rightToLeftSourceView:sourceView];
            break;
    }
}

- (void)moveDestinationView:(nonnull UIView *)destinationView rightToLeftSourceView:(nonnull UIView *)sourceView
{
    NSParameterAssert(destinationView != nil);
    NSParameterAssert(sourceView != nil);
    sourceView.frame = CGRectMakeFromPointSize(CGPointZero, self.container.view.frame.size);
    UIView *containerView = self.container.view;
    destinationView.frame = CGRectMake(containerView.frame.size.width, 0,
                                       containerView.frame.size.width, containerView.frame.size.height);

    [self.container transitionFromViewController:self.container.embeddedViewController
                                toViewController:self.destinationViewController
                                        duration:.25 options:0
                                      animations:^{
                                          sourceView.frame = CGRectMake(-containerView.frame.size.width, 0,
                                                                        containerView.frame.size.width, containerView.frame.size.height);
                                          destinationView.frame = CGRectMakeFromPointSize(CGPointZero, containerView.frame.size);
                                      }
                                      completion:^(BOOL finished) {
                                          [self finishTransaction];
                                      }];
}

- (void)moveDestinationView:(nonnull UIView *)destinationView leftToRightSourceView:(nonnull UIView *)sourceView
{
    NSParameterAssert(destinationView != nil);
    NSParameterAssert(sourceView != nil);
    sourceView.frame = CGRectMakeFromPointSize(CGPointZero, self.container.view.frame.size);
    UIView *containerView = self.container.view;
    destinationView.frame = CGRectMake(-containerView.frame.size.width, 0,
                                       containerView.frame.size.width, containerView.frame.size.height);

    [self.container transitionFromViewController:self.container.embeddedViewController
                                toViewController:self.destinationViewController
                                        duration:.25 options:0
                                      animations:^{
                                          sourceView.frame = CGRectMake(containerView.frame.size.width, 0,
                                                                        containerView.frame.size.width, containerView.frame.size.height);
                                          destinationView.frame = CGRectMakeFromPointSize(CGPointZero, containerView.frame.size);
                                      }
                                      completion:^(BOOL finished) {
                                          [self finishTransaction];
                                      }];
}

- (void)finishTransaction
{
    if (self.container.embeddedViewController) {
        [self.container.embeddedViewController removeFromParentViewController];
        [self.container.embeddedViewController.view removeFromSuperview];
    }
    [self.destinationViewController didMoveToParentViewController:self.container];
    self.container.embeddedViewController = self.destinationViewController;
    if (self.container.delegate) {
        [self.container.delegate swipeContainer:self.container didSwipeToViewController:self.destinationViewController];
    }
}

@end