//
//  BookingDetailsViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "BookingDetailsViewController.h"
#import "SBSession.h"
#import "SBBookingInfo.h"
#import "DSSectionDataSource.h"
#import "ACHKeyValueTableViewCell.h"
#import "ACHAdditionalFieldTableViewCell.h"
#import "NSError+SimplyBook.h"
#import "AddBookingViewController.h"
#import "NSDate+TimeManipulation.h"
#import "SBGetBookingDetailsRequest.h"
#import "SBGetBookingsRequest.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "UIColor+SimplyBookColors.h"
#import "BookingApproveStatusTableViewCell.h"
#import "SBPluginsRepository.h"

static NSString *const kBookingDetailsKeyValueCellReuseIdentifier = @"kBookingDetailsKeyValueCellReuseIdentifier";
static NSString *const kBookingDetailsFieldsCellReuseIdentifier = @"kBookingDetailsFieldsCellReuseIdentifier";
static NSString *const kBookingDetailsActionCellReuseIdentifier = @"kBookingDetailsActionCellReuseIdentifier";
static NSString *const kBookingDetailsApproveStatusNewCellReuseIdentifier = @"kBookingDetailsApproveStatusNewCellReuseIdentifier";

@interface BookingDetailsViewController ()
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) SBBookingInfo *booking;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSNumberFormatter *moneyFormatter;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) DSSectionDataSource *approveBookingSection;

@end

@implementation BookingDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                 forBarPosition:UIBarPositionAny
                                                     barMetrics:UIBarMetricsDefault];
    
    SBUser *user = [SBSession defaultSession].user;
    NSAssert(user != nil, @"no user found");
    if (![user hasAccessToACLRule:SBACLRuleEditBooking]) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    /** UI hack */
    UIView *statusBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    statusBarBackground.translatesAutoresizingMaskIntoConstraints = NO;
    statusBarBackground.backgroundColor = self.navigationController.navigationBar.barTintColor;
    [self.view addSubview:statusBarBackground];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[statusBarBackground]|" options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(statusBarBackground)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[statusBarBackground(==20)]" options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(statusBarBackground)]];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHKeyValueTableViewCell" bundle:nil] forCellReuseIdentifier:kBookingDetailsKeyValueCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHAdditionalFieldTableViewCell" bundle:nil] forCellReuseIdentifier:kBookingDetailsFieldsCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"BookingApproveStatusTableViewCell" bundle:nil] forCellReuseIdentifier:kBookingDetailsApproveStatusNewCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kBookingDetailsActionCellReuseIdentifier];
    self.tableView.estimatedRowHeight = 30.;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    pendingRequests = [NSMutableArray array];
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLS(@"Close",@"")
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self action:@selector(backAction:)];
    }
    
    [self loadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingBookingsDidUpdateNotificationHandler:)
                                                 name:kSBPendingBookings_DidUpdateNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SBSession defaultSession] cancelRequests:pendingRequests];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBPendingBookings_DidUpdateNotification
                                                  object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    self.tabBarController.tabBar.hidden = [self.traitCollection isWideLayout] && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notifications

- (void)pendingBookingsDidUpdateNotificationHandler:(NSNotification *)notification
{
    if (notification.object != self && [notification.userInfo[kSBPendingBookings_BookingIDKey] isEqualToString:self.bookingID]) {
        [self loadData];
    }
}

#pragma mark - Requests

- (void)loadData
{
    SBRequest *request = [[SBSession defaultSession] getBookingDetails:self.bookingID callback:^(SBResponse<SBBookingInfo *> *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (!response.error) {
            if (self.booking && ![self.booking.clientID isEqualToString:response.result.clientID]) {
                self.clientName = nil;
                self.clientEmail = nil;
                self.clientPhone = nil;
            }
            self.booking = response.result;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                [self reloadSections];
                SBUser *user = [SBSession defaultSession].user;
                NSAssert(user != nil, @"no user found");
                if ([self.booking.isConfirmed boolValue] && [user hasAccessToACLRule:SBACLRuleEditBooking]) {
                    [self showCancelBookingButton];
                }
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.cancelButton.enabled = YES;
                [self.tableView reloadData];
            });
        } else if (!response.canceled){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.cancelButton.enabled = YES;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"") message:[response.error message]
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
            });

        }
    }];
    
    self.activityIndicator.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.cancelButton.enabled = NO;
    [pendingRequests addObject:request.GUID];
    [[SBSession defaultSession] performReqeust:request];
}

- (void)loadClientData
{
    NSAssert(self.booking != nil && self.booking.clientID != nil, @"invalid params");
    SBRequest *request = [[SBSession defaultSession] getClientWithId:self.booking.clientID callback:^(SBResponse<NSDictionary *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityIndicator.hidden = YES;
            if (!response.error) {
                self.clientName = response.result[@"name"];
                self.clientEmail = response.result[@"email"];
                self.clientPhone = response.result[@"phone"];
                [self reloadSections];
                [self.tableView reloadData];
            }
        });
    }];
    [pendingRequests addObject:request.GUID];
    self.activityIndicator.hidden = NO;
    [[SBSession defaultSession] performReqeust:request];
}

- (SBRequest *)cancelBookingRequest
{
    SBRequest *request = [[SBSession defaultSession] cancelBookingWithID:self.bookingID callback:^(SBResponse *response) {
        if (response.error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [pendingRequests removeObject:response.requestGUID];
                self.activityIndicator.hidden = YES;
                self.cancelButton.enabled = YES;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:[NSString stringWithFormat:@"Booking not canceled. %@", [response.error message]]
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
            });
        } else if (!response.canceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [pendingRequests removeObject:response.requestGUID];
                [self invalidateCaches];
                
                if (self.onBookingCanceledHandler) {
                    self.onBookingCanceledHandler(self.bookingID);
                }
                
                self.activityIndicator.hidden = YES;
                if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            });
        }
    }];
    return request;
}

- (void)setBookingWithID:(NSString *)bookingID approved:(BOOL)approved
{
    SBRequest *request = [[SBSession defaultSession] setBookingApproved:approved bookingID:bookingID callback:^(SBResponse<id> * _Nonnull response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [pendingRequests removeObject:response.requestGUID];
            NSInteger sectionIndex = [self.sections indexOfObject:self.approveBookingSection];
            if (!response.error) {
                if (sectionIndex == NSNotFound) {
                    [self reloadSections];
                    return;
                }
                [self invalidateCaches];
                self.sections[sectionIndex] = [self approveBookingSectionForApproveStatus:(approved ? kSBBookingInfoApproveStatusApproved : kSBBookingInfoApproveStatusCancelled)];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                self.activityIndicator.hidden = YES;
                self.cancelButton.enabled = YES;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:kSBPendingBookings_DidUpdateNotification
                                                                    object:self
                                                                  userInfo:@{kSBPendingBookings_BookingIDKey: bookingID}];
            }
            else {
                NSString *errorMessage = (approved ? NSLS(@"An error occurred during approving booking. Please try again later.",@"")
                                          : NSLS(@"An error occurred during booking cancellation. Please try again later.",@""));
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:errorMessage
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                [alert show];
            }
        });
    }];
    self.activityIndicator.hidden = NO;
    self.cancelButton.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [pendingRequests addObject:request.GUID];
    [[SBSession defaultSession] performReqeust:request];
}

#pragma mark -

- (void)invalidateCaches
{
    SBRequest *getPendingBookingsRequest = [[SBSession defaultSession] getPendingBookingsWithCallback:nil];
    [[SBCache cache] invalidateCacheForRequest:getPendingBookingsRequest];
    
    SBGetBookingDetailsRequest *getBookingDetailsRequest = [SBGetBookingDetailsRequest new];
    getBookingDetailsRequest.bookingID = self.bookingID;
    [[SBCache cache] invalidateCacheForRequest:getBookingDetailsRequest];
    
    [[SBCache cache] invalidateCacheForRequestClass:[SBGetBookingsRequest class]];
}

- (DSSectionDataSource *)approveBookingSectionForApproveStatus:(NSString *)approveStatus
{
    DSSectionDataSource *sectionDataSource = [DSSectionDataSource new];
    sectionDataSource.sectionTitle = NSLS(@"Approval Status",@"");
    if ([approveStatus isEqualToString:kSBBookingInfoApproveStatusNew]) {
        SBUser *user = [SBSession defaultSession].user;
        NSAssert(user != nil, @"no user found");
        if ([user hasAccessToACLRule:SBACLRuleEditBooking]) {
            sectionDataSource.cellReuseIdentifier = kBookingDetailsApproveStatusNewCellReuseIdentifier;
            [sectionDataSource addItem:[KeyValueRow rowWithKey:@"status" value:self.booking.approveStatus]];
        }
        else {
            sectionDataSource.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
            KeyValueRow *row = [KeyValueRow rowWithKey:NSLS(@"Status:",@"") value:@""];
            row.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            row.accessoryView.layer.cornerRadius = row.accessoryView.frame.size.width / 2.;
            row.accessoryView.layer.masksToBounds = YES;
            row.value = NSLS(@"New",@"");
            row.accessoryView.backgroundColor = [UIColor colorWithRed:0.34 green:0.67 blue:0.88 alpha:1.000];
            [sectionDataSource addItem:row];
        }
    }
    else {
        sectionDataSource.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
        KeyValueRow *row = [KeyValueRow rowWithKey:NSLS(@"Status:",@"") value:@""];
        row.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        row.accessoryView.layer.cornerRadius = row.accessoryView.frame.size.width / 2.;
        row.accessoryView.layer.masksToBounds = YES;
        if ([approveStatus isEqualToString:kSBBookingInfoApproveStatusApproved]) {
            row.value = NSLS(@"Approved",@"");
            row.accessoryView.backgroundColor = [UIColor colorWithRed:0.408 green:0.776 blue:0.255 alpha:1.000];
        }
        else {
            row.value = NSLS(@"Cancelled",@"");
            row.accessoryView.backgroundColor = [UIColor colorWithRed:0.969 green:0.329 blue:0.306 alpha:1.000];
        }
        [sectionDataSource addItem:row];
    }
    return sectionDataSource;
}

- (void)reloadSections
{
    if (!self.sections) {
        self.sections = [NSMutableArray array];
    } else {
        [self.sections removeAllObjects];
    }
    DSSectionDataSource *generalSection = [DSSectionDataSource new];
    generalSection.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
    generalSection.estimatedRowHeight = 30;
    generalSection.sectionTitle = NSLS(@"General",@"");
    [generalSection addItem:[KeyValueRow rowWithKey:NSLS(@"Service:",@"") value:self.booking.eventName]];
    [generalSection addItem:[KeyValueRow rowWithKey:NSLS(@"Staff:",@"") value:self.booking.unitName]];
    [generalSection addItem:[KeyValueRow rowWithKey:NSLS(@"Code:",@"") value:self.booking.code]];
    [generalSection addItem:[KeyValueRow rowWithKey:NSLS(@"Start:",@"") value:[self.dateFormatter stringFromDate:self.booking.startDate]]];
    [generalSection addItem:[KeyValueRow rowWithKey:NSLS(@"End:",@"") value:[self.dateFormatter stringFromDate:self.booking.endDate]]];
    if (self.booking.status) {
        KeyValueRow *row = [KeyValueRow rowWithKey:NSLS(@"Status:",@"") value:self.booking.status.name];
        row.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        row.accessoryView.layer.cornerRadius = row.accessoryView.frame.size.width / 2.;
        row.accessoryView.layer.masksToBounds = YES;
        row.accessoryView.backgroundColor = [UIColor colorFromHEXString:self.booking.status.HEXColor];
        [generalSection addItem:row];
    }
//    if (![self.booking.isConfirmed boolValue]) {
//        ActionRow *warning = [ActionRow actionRowWithTitle:NSLS(@"Not confirmed",@"") iconName:@"warning-icon"];
//        warning.iconTintColor = [UIColor colorWithRed:1. green:221./255. blue:85./255. alpha:1];
//        warning.cellReuseIdentifier = kBookingDetailsActionCellReuseIdentifier;
//        [generalSection addItem:warning];
//    }
    [self.sections addObject:generalSection];
    
    if (self.booking.approveStatus) {
        self.approveBookingSection = [self approveBookingSectionForApproveStatus:self.booking.approveStatus];
        [self.sections addObject:self.approveBookingSection];
    }
    
    if (self.clientName) {
        DSSectionDataSource *clientSection = [DSSectionDataSource new];
        clientSection.cellReuseIdentifier = kBookingDetailsActionCellReuseIdentifier;
        clientSection.sectionTitle = NSLS(@"Client",@"");
        [clientSection addItem:[ActionRow actionRowWithTitle:self.clientName iconName:nil]];
        if (self.clientPhone) {
            ActionRow *phone = [ActionRow actionRowWithTitle:self.clientPhone iconName:@"company-action-phone"];
            phone.tintColor = self.view.tintColor;
            NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", self.clientPhone]];
            if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
                phone.action = ^(UIViewController *controller){
                    if (pendingRequests.count == 0) {
                        [[UIApplication sharedApplication] openURL:phoneURL];
                    }
                };
            }
            [clientSection addItem:phone];
        }
        if (self.clientEmail) {
            ActionRow *email = [ActionRow actionRowWithTitle:self.clientEmail iconName:@"company-action-email"];
            email.tintColor = self.view.tintColor;
            if ([MFMailComposeViewController canSendMail]) {
                email.action = ^(UIViewController *controller) {
                    if (pendingRequests.count == 0) {
                        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
                        composer.mailComposeDelegate = self;
                        [composer setToRecipients:@[self.clientEmail]];
                        [controller presentViewController:composer animated:YES completion:nil];
                    }
                };
            }
            [clientSection addItem:email];
        }
        [self.sections addObject:clientSection];
    } else if (self.booking.clientID) {
        [self loadClientData];
    }
    
    if (self.booking.location) {
        DSSectionDataSource *locationSection = [DSSectionDataSource new];
        locationSection.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
        locationSection.estimatedRowHeight = 30;
        locationSection.sectionTitle = NSLS(@"Location", @"");
        [locationSection addItem:[KeyValueRow rowWithKey:NSLS(@"Name:",@"") value:self.booking.location.title]];
        [locationSection addItem:[KeyValueRow rowWithKey:NSLS(@"Address:",@"") value:[self.booking.location address]]];
        [locationSection addItem:[KeyValueRow rowWithKey:NSLS(@"Phone:",@"") value:self.booking.location.phone]];
        [self.sections addObject:locationSection];
    }
    
    if (self.booking.price) {
        [self.moneyFormatter setCurrencyCode:self.booking.price.currency];
        DSSectionDataSource *priceSection = [DSSectionDataSource new];
        priceSection.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
        priceSection.estimatedRowHeight = 30;
        priceSection.sectionTitle = NSLS(@"Payments",@"");
        UIView *statusMark = [[UIView alloc] initWithFrame:CGRectMake(0,0, 10, 10)];
        statusMark.layer.cornerRadius = statusMark.frame.size.width / 2.;
        statusMark.layer.masksToBounds = YES;
        NSString *paymentStatus = @"";
        if ([self.booking.price.status isEqualToString:@"paid"]) {
            if ([self.booking.price.paymentProcessor isEqualToString:@"delay"]) {
                paymentStatus = NSLS(@"(Pay later)",@"");
                statusMark.backgroundColor = [UIColor colorWithRed:1. green:221./255. blue:85./255. alpha:1];
            }
            else {
                statusMark = nil;
            }
        }
        else if ([self.booking.price.status isEqualToString:@"cancel"]) {
            paymentStatus = NSLS(@"(Cancelled)",@"");
            statusMark.backgroundColor = [UIColor redColor];
        }
        else if ([self.booking.price.status isEqualToString:@"not_paid"]) {
            paymentStatus = NSLS(@"(Not paid)",@"");
            statusMark.backgroundColor = [UIColor redColor];
        }
        else if ([self.booking.price.status isEqualToString:@"error"]) {
            paymentStatus = NSLS(@"(Error)",@"");
            statusMark.backgroundColor = [UIColor redColor];
        }
        NSString *priceString = [NSString stringWithFormat:@"%@ %@", [self.moneyFormatter stringFromNumber:self.booking.price.amount],
                                          paymentStatus];
        KeyValueRow *row = [KeyValueRow rowWithKey:NSLS(@"Amount:",@"") value:priceString];
        row.accessoryView = statusMark;
        [priceSection addItem:row];
        [priceSection addItem:[KeyValueRow rowWithKey:NSLS(@"Date:",@"")
                                                value:[self.dateFormatter stringFromDate:self.booking.price.operationDate]]];
        [self.sections addObject:priceSection];
    }

    if (self.booking.promo) {
        DSSectionDataSource *promoSection = [DSSectionDataSource new];
        promoSection.cellReuseIdentifier = kBookingDetailsKeyValueCellReuseIdentifier;
        promoSection.estimatedRowHeight = 30;
        promoSection.sectionTitle = NSLS(@"Promotion", @"");
        [promoSection addItem:[KeyValueRow rowWithKey:NSLS(@"Code:",@"") value:self.booking.promo.code]];
        [promoSection addItem:[KeyValueRow rowWithKey:NSLS(@"Discount:",@"")
                                                value:[NSString stringWithFormat:@"%.2f%%", self.booking.promo.discount * 100]]];
        [self.sections addObject:promoSection];
    }
    
    if (self.booking.additionalFields && self.booking.additionalFields.count) {
        DSSectionDataSource *additionalFieldSection = [DSSectionDataSource new];
        additionalFieldSection.estimatedRowHeight = 40;
        additionalFieldSection.cellReuseIdentifier = kBookingDetailsFieldsCellReuseIdentifier;
        additionalFieldSection.sectionTitle = NSLS(@"Additional Fields",@"");
        for (SBBookingInfoAdditionalField *field in self.booking.additionalFields) {
            [additionalFieldSection addItem:[AdditionalFieldRow rowWithAdditionalField:field]];
        }
        [self.sections addObject:additionalFieldSection];
    }
}

- (void)showCancelBookingButton
{
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelButton.backgroundColor = [UIColor colorWithRed:0.969 green:0.329 blue:0.306 alpha:1.000];
    self.cancelButton.layer.cornerRadius = 5;
    self.cancelButton.layer.masksToBounds = YES;
    [self.cancelButton setTitle:NSLS(@"Cancel",@"") forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelBookingAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
    footer.backgroundColor = self.tableView.backgroundColor;
    [footer addSubview:self.cancelButton];
    [footer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cancelButton]-|" options:0
                                                                   metrics:nil views:@{@"cancelButton": self.cancelButton}]];
    [footer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[cancelButton(==40)]-|" options:0
                                                                   metrics:nil views:@{@"cancelButton": self.cancelButton}]];
    CGSize footerSize = [footer systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    footer.frame = CGRectMake(0, 0, self.tableView.frame.size.width, footerSize.height);
    self.tableView.tableFooterView = footer;
}

#pragma mark -

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter) {
        return _dateFormatter;
    }
    _dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    return _dateFormatter;
}

- (NSNumberFormatter *)moneyFormatter
{
    if (_moneyFormatter) {
        return _moneyFormatter;
    }
    _moneyFormatter = [NSNumberFormatter new];
    [_moneyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return _moneyFormatter;
}

#pragma mark - Actions

- (void)cancelBookingAction:(id)sender
{
    SBRequest *request = [self cancelBookingRequest];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLS(@"Warning",@"")
                                                                             message:NSLS(@"Are you sure you want to cancel this appointment?", @"")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLS(@"No, wait",@"")
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLS(@"Yes, do it",@"")
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    self.activityIndicator.hidden = NO;
                                    self.cancelButton.enabled = NO;
                                    [pendingRequests addObject:request.GUID];
                                    [[SBSession defaultSession] performReqeust:request];
                                }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)backAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sections[section] items] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSSectionDataSource *sectionDataSource = self.sections[indexPath.section];
    if ([sectionDataSource.cellReuseIdentifier isEqualToString:kBookingDetailsApproveStatusNewCellReuseIdentifier]) {
        BookingApproveStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBookingDetailsApproveStatusNewCellReuseIdentifier
                                                                                  forIndexPath:indexPath];
        cell.approveAction = ^{
            if (pendingRequests.count == 0) {
                [self setBookingWithID:self.booking.bookingID approved:YES];
            }
        };
        cell.cancelAction = ^{
            if (pendingRequests.count == 0) {
                [self setBookingWithID:self.booking.bookingID approved:NO];
            }
        };
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[sectionDataSource cellReuseIdentifierForIndexPath:indexPath]
                                                                forIndexPath:indexPath];
        [sectionDataSource configureCell:cell forRowAtIndexPath:indexPath];
        DSSectionRow *item = sectionDataSource.items[indexPath.row];
        if ([item isKindOfClass:[ActionRow class]] && [(ActionRow *)item action] != NULL) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSSectionDataSource *sectionDataSource = self.sections[indexPath.section];
    return sectionDataSource.estimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSSectionDataSource *sectionDataSource = self.sections[indexPath.section];
    return sectionDataSource.estimatedRowHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DSSectionDataSource *sectionDataSource = self.sections[section];
    return sectionDataSource.sectionTitle;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (pendingRequests.count > 0) {
        return;
    }
    DSSectionDataSource *sectionDataSource = self.sections[indexPath.section];
    DSSectionRow *item = sectionDataSource.items[indexPath.row];
    if ([item isKindOfClass:[ActionRow class]] && [(ActionRow *)item action] != NULL) {
        ActionRow *command = (ActionRow *)item;
        command.action(self);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 // edit booking
    AddBookingViewController *controller = (AddBookingViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
    controller.bookingForm = [SBBookingForm new];
    controller.bookingForm.bookingID = self.bookingID;
    [controller.bookingForm setEventID:self.booking.eventID withDuration:0];
    controller.serviceName = self.booking.eventName;
    controller.bookingForm.unitID = self.booking.unitID;
    controller.performerName = self.booking.unitName;
    controller.bookingForm.startDate = self.booking.startDate;
    controller.bookingForm.startTime = self.booking.startDate;
    controller.bookingForm.endTime = self.booking.endDate;
    if (self.booking.location) {
        controller.bookingForm.locationID = self.booking.location.locationID;
    }
    if (self.clientEmail && self.clientName && self.clientPhone) {
        controller.bookingForm.client = @{@"id": self.booking.clientID,
                                          @"name": self.clientName,
                                          @"email": self.clientEmail,
                                          @"phone": self.clientPhone};
    }
    else if (self.booking.clientID) {
        controller.bookingForm.client = @{@"id": self.booking.clientID};
    }
    controller.bookingStatus = self.booking.status;
    controller.additionalFieldsPreset = self.booking.additionalFields;
    controller.bookingCreatedHandler = ^(UIViewController *_controller) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_controller dismissViewControllerAnimated:YES completion:nil];
            [self loadData];
        });
    };
                                      
}

@end
