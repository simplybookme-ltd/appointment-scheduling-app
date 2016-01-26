//
//  SwipeContainerViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSwipeContainerViewControllerInitialSegueIdentifier;

typedef NS_ENUM(NSInteger, SwipeViewsDirection) {
    SwipeViewsNoDirection,
    SwipeViewsLeftToRightDirection,
    SwipeViewsRightToLeftDirection
};

@interface SwipeViewsStoryboardSegue : UIStoryboardSegue

@property (nonatomic) SwipeViewsDirection direction;

@end

@class SwipeContainerViewController;

@protocol SwipeContainerViewControllerDelegate <NSObject>

- (void)swipeContainer:(SwipeContainerViewController *)swipeContainer willSwipeToViewController:(__kindof UIViewController *)viewController;
- (void)swipeContainer:(SwipeContainerViewController *)swipeContainer didSwipeToViewController:(__kindof UIViewController *)viewController;

@end

@interface SwipeContainerViewController : UIViewController

@property (nonatomic, strong, nullable) __kindof UIViewController *embeddedViewController;
@property (nonatomic, weak, nullable) IBOutlet NSObject <SwipeContainerViewControllerDelegate> *delegate;

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender
                    swipeDirection:(SwipeViewsDirection)direction;

@end

NS_ASSUME_NONNULL_END
