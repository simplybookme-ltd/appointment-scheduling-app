//
//  CalendarViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarViewController.h"
#import "SBGetBookingsFilter.h"
#import "FilterViewController.h"
#import "UIColor+SimplyBookColors.h"

typedef NS_ENUM(NSInteger, CalendarViewType)
{
    CalendarViewDayType,
    CalendarViewWeekType
};

@interface CalendarViewController () <FilterViewControllerDelegate>

@property (nonatomic, weak, nullable) UIViewController <CalendarViewContainerChildController> *childController;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *preferencesBarButton;
@property (nonatomic, weak, nullable) SwipeContainerViewController *swipeContainer;
@property (nonatomic) CalendarViewType calendarViewType;

@end

@implementation CalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIView *statusBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    statusBarBackground.translatesAutoresizingMaskIntoConstraints = NO;
    statusBarBackground.backgroundColor = [UIColor sb_navigationBarColor];
    [self.view addSubview:statusBarBackground];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[statusBarBackground]|" options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(statusBarBackground)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[statusBarBackground(==20)]" options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(statusBarBackground)]];

    if (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular || self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular) {
        if (self.preferencesBarButton) {
            NSMutableArray *items = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
            [items removeObject:self.preferencesBarButton];
            self.navigationItem.rightBarButtonItems = items;
            self.preferencesBarButton = nil;
        }
    }

    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[NSLS(@"Day",@""), NSLS(@"Week",@"")]];
    control.selectedSegmentIndex = CalendarViewDayType;
    [control addTarget:self action:@selector(calendarViewTypeChangedAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = control;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /**
     * a hack to make navigation bar filled with solid color with no lines on it.
     */
    self.navigationController.navigationBar.backgroundColor = self.navigationController.navigationBar.barTintColor;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"transparent"]
                                                 forBarPosition:UIBarPositionAny
                                                     barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    /**
     * back to default navigation bar configuration.
     * @see viewWillAppear
     */
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                 forBarPosition:UIBarPositionAny
                                                     barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
}


#pragma mark - Actions

- (void)calendarViewTypeChangedAction:(UISegmentedControl *)sender
{
    SwipeViewsDirection direction = (sender.selectedSegmentIndex > self.calendarViewType ? SwipeViewsRightToLeftDirection : SwipeViewsLeftToRightDirection);
    switch (sender.selectedSegmentIndex) {
        case CalendarViewDayType:
            [self.swipeContainer performSegueWithIdentifier:@"calendar-view-day-type" sender:self swipeDirection:direction];
            break;
        case CalendarViewWeekType:
            [self.swipeContainer performSegueWithIdentifier:@"calendar-view-week-type" sender:self swipeDirection:direction];
            break;
        default:
            NSAssertFail();
    }
    self.calendarViewType = sender.selectedSegmentIndex;
}

- (IBAction)addBookingAction:(id)sender
{
    [self.childController showAddBookingForm];
}

#pragma mark - SwipeContainerViewControllerDelegate

- (void)swipeContainer:(nonnull SwipeContainerViewController *)swipeContainer willSwipeToViewController:(nonnull UIViewController *)viewController
{
    NSParameterAssert(swipeContainer != nil);
    NSParameterAssert(viewController != nil);
    NSParameterAssert([viewController conformsToProtocol:@protocol(CalendarViewContainerChildController)]);
    if (self.childController) {
        [self.childController willRemoveFromCalendarViewContainer:self];
    }
    UIViewController <CalendarViewContainerChildController> *child = (UIViewController <CalendarViewContainerChildController> *) viewController;
    [child willEmbedToCalendarViewContainer:self];
}

- (void)swipeContainer:(nonnull SwipeContainerViewController *)swipeContainer didSwipeToViewController:(nonnull UIViewController *)viewController
{
    NSParameterAssert(swipeContainer != nil);
    NSParameterAssert(viewController != nil);
    NSParameterAssert([viewController conformsToProtocol:@protocol(CalendarViewContainerChildController)]);
    if (self.childController) {
        [self.childController didRemoveFromCalendarViewContainer:self];
    }
    self.childController = (UIViewController <CalendarViewContainerChildController> *) viewController;
    [self.childController didEmbedToCalendarViewContainer:self];
}

#pragma mark - FilterViewController delegate

- (void)filterController:(nonnull FilterViewController *)filterController didSetNewFilter:(nonnull SBGetBookingsFilter *)filter
                   reset:(BOOL)reset
{
    NSParameterAssert(filterController != nil);
    NSParameterAssert(filter != nil);
    [self dismissViewControllerAnimated:YES completion:nil];
    if (reset) {
        self.filterBarButton.image = [UIImage imageNamed:@"filter"];
    } else {
        self.filterBarButton.image = [UIImage imageNamed:@"filter-remove"];
    }
    [self.childController filterDidChange:filter requiresReset:reset];
}

- (void)filterControllerDidCancel:(FilterViewController *)filterController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation Stack

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed-swipe-container"]) {
        /**
         * because it is not possible to connect objects from different storyboard screens we need to
         * configure swipe container delegate by catching 'embed' segue
         */
        self.swipeContainer = (SwipeContainerViewController *) segue.destinationViewController;
        self.swipeContainer.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"applyFilter"]) {
        if (segue.destinationViewController.popoverPresentationController) {
            segue.destinationViewController.popoverPresentationController.backgroundColor = [UIColor sb_navigationBarColor];
        }
        FilterViewController *controller = (FilterViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
        controller.initialFilter = self.childController.getBookingsFilter;
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"preferencesSegue"]) {
        if (segue.destinationViewController.popoverPresentationController) {
            segue.destinationViewController.popoverPresentationController.backgroundColor = segue.destinationViewController.view.backgroundColor;
        }
    }
}

@end
