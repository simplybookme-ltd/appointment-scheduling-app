//
//  AddBookingViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "AddBookingViewController.h"
#import "NSDate+TimeManipulation.h"
#import "SBSession.h"
#import "SBCompanyInfo.h"
#import "ACHRightDetailsTableViewCell.h"
#import "SBWorkingHoursMatrix.h"
#import "SBRequestsGroup.h"
#import "FilterListSelectorViewController.h"
#import "ClientListViewController.h"
#import "ACHAdditionalFieldsDataSource.h"
#import "ACHAdditionalFieldEditorController.h"
#import "SBValidator.h"
#import "SBServerIDValidator.h"
#import "NSError+SimplyBook.h"
#import "SBGetBookingDetailsRequest.h"
#import "SBGetBookingsRequest.h"
#import "SBBookingFormHoursSelectorDataSource.h"
#import "SBBookingStatusesCollection.h"
#import "SBBookingInfo.h"
#import "SBPerformer.h"
#import "SBPerformer+FilterListSelector.h"
#import "SBService.h"
#import "SBService+FilterListSelector.h"
#import "SBPluginsRepository.h"
#import "LocationsListViewController.h"
#import "SBUser.h"

#define IsLocationsEnabled ([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryLocationsPlugin].boolValue && self.locations.count)
#define IsAdditionalFieldsEnabled (self.bookingForm.additionalFields && self.bookingForm.additionalFields.count)

#define BookingFormGeneralSection 0
#define BookingFormLocationSection (IsLocationsEnabled ? (BookingFormGeneralSection + 1) : (BookingFormGeneralSection))
#define BookingFormAdditionalFieldsSection (IsAdditionalFieldsEnabled ? (BookingFormLocationSection) + 1 : (BookingFormLocationSection))

NS_ENUM(NSInteger, BookingFormFields)
{
    BookingFormClientField,
    BookingFormServiceField,
    BookingFormPerformerField,
    BookingFormStartDateField,
    BookingFormStartTimeField,
    BookingFormEndTimeField,
    BookingFormStatusField
};

#define kControlTag 100

@interface AddBookingViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, FilterListSelectorDelegate>
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, weak, nullable) IBOutlet UITableView *tableView;
@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong, nonnull) NSDateFormatter *timeFormatter;
@property (nonatomic, strong, nonnull) NSDateIntervalFormatter *intervalFormatter;

@property (nonatomic, strong, nullable) NSIndexPath *pickerIndexPath;
@property (nonatomic, strong, nonnull) ACHAdditionalFieldsDataSource *additionalFieldsDS;
@property (nonatomic, strong, nonnull) SBBookingFormHoursSelectorDataSource *hoursSelectorDataSource;
@property (nonatomic, strong, nullable) SBPerformersCollection *performers;
@property (nonatomic, strong, nullable) SBServicesCollection *services;
@property (nonatomic, strong, nullable) SBBookingStatusesCollection *statusesCollection;
@property (nonatomic, strong, nullable) NSArray <NSDictionary *> *locations;

@property (nonatomic, strong, nullable) SBRequest *getWorkDaysTimesRequest;
@property (nonatomic, strong, nullable) SBRequest *getAdditionalFieldsRequest;
@property (nonatomic, strong, nullable) SBRequest *getLocationsRequest;
@property (nonatomic) BOOL observing;

@end

@implementation AddBookingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    pendingRequests = [NSMutableArray array];
    
    self.additionalFieldsDS = [ACHAdditionalFieldsDataSource new];
    [self.additionalFieldsDS configureTableView:self.tableView];
    
    if (!self.bookingForm) {
        self.bookingForm = [SBBookingForm new];
        if (self.preferedPerformerID) {
            self.bookingForm.unitID = self.preferedPerformerID;
        }
    }
    else {
        self.title = NSLS(@"Change Booking",@"");
        [self.additionalFieldsDS setAdditionalFields:self.bookingForm.additionalFields];
    }
    
    if (self.initialDate) {
        self.bookingForm.startDate = self.initialDate;
    }

    self.hoursSelectorDataSource = [SBBookingFormHoursSelectorDataSource new];
    self.hoursSelectorDataSource.timeFormatter = self.timeFormatter;
    
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHRightDetailsTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"cell"];
    [self.tableView reloadData];
    
    SBSession *session = [SBSession defaultSession];
    
    SBUser *user = [SBSession defaultSession].user;
    NSAssert(user != nil, @"no user found");
    if ((self.bookingForm.bookingID && ![user hasAccessToACLRule:SBACLRuleEditBooking])
        || (!self.bookingForm.bookingID && ![user hasAccessToACLRule:SBACLRuleCreateBooking]))
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    SBRequestsGroup *group = [SBRequestsGroup new];
    
    SBRequest *request = [session getCompanyInfoWithCallback:^(SBResponse *response) {
        if (!response.error) {
            SBCompanyInfo *companyInfo = response.result;
            self.timeFrameStep = [companyInfo.timeframe integerValue];
            self.bookingForm.timeframe = [companyInfo.timeframe integerValue];
        }
    }];
    [group addRequest:request];
    
    request = [session getCompanyParam:kSBCompanyClientRequiredFieldsParamKey callback:^(SBResponse<NSString *> * _Nonnull response) {
        // nothing to do. but need to call this method to cache result for AddClientViewController.
    }];
    [group addRequest:request];
    
    request = [session getEventList:^(SBResponse<SBServicesCollection *> *response) {
        if (!response.error) {
            self.services = response.result;
            if (self.bookingForm.eventID) {
                [self.bookingForm setEventID:self.bookingForm.eventID withDuration:[self.services[self.bookingForm.eventID].duration integerValue]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:BookingFormServiceField inSection:0]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
            else if (self.services.count == 1) {
                NSString *eventID = self.services[0].serviceID;
                [self.bookingForm setEventID:eventID withDuration:[self.services[eventID].duration integerValue]];
            }
        }
    }];
    [group addRequest:request];
    
    request = [session getUnitList:^(SBResponse *response) {
        if (!response.error) {
            SBUser *user = [[SBSession defaultSession] user];
            NSAssert(user != nil, @"no user found");
            if ([user hasAccessToACLRule:SBACLRulePerformersFullListAccess]) {
                self.performers = response.result;
            } else {
                SBPerformersCollection *collection = response.result;
                self.performers = [collection collectionWithObjectsPassingTest:^BOOL(SBPerformer * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                    *stop = [object.performerID isEqualToString:user.associatedPerformerID];
                    return *stop;
                }];
            }
            if (self.bookingForm.unitID) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:BookingFormPerformerField inSection:0]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
            else if (self.performers.count == 1) {
                self.bookingForm.unitID = self.performers[0].performerID;
            }
        }
    }];
    [group addRequest:request];

    request = [session getStatusesList:^(SBResponse <SBBookingStatusesCollection *> *response) {
        if (!response.error) {
            self.statusesCollection = response.result;
            // use sync method to sync tableview reload
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } else {
            self.statusesCollection = nil;
        }
    }];
    [group addRequest:request];
    
    request = [session isPluginActivated:kSBPluginRepositoryStatusPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
        // nothing to do
    }];
    [group addRequest:request];
    
    NSNumber *locationPluginStatus = [[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryLocationsPlugin];
    if (!locationPluginStatus) {
        SBRequest *pluginStatusRequest = [session isPluginActivated:kSBPluginRepositoryLocationsPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
            if (response.result) {
                [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryLocationsPlugin enabled:response.result.boolValue];
            }
        }];
        [group addRequest:pluginStatusRequest];
    }
    
    group.callback = ^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (response.error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:NSLS(@"An error occurred. Please try again later.",@"")
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
                [self cancelAction:nil];
            });

        } else {
            [self addObservers];
            [self loadWorkingHoursForStartDate];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.bookingForm.bookingID) {
                    [self loadAdditionalFields];
                }
                if ([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryLocationsPlugin].boolValue) {
                    [self loadLocations];
                }
                self.activityIndicator.hidden = YES;
            });
        }
    };
    [pendingRequests addObject:group.GUID];
    [session performReqeust:group];

    self.activityIndicator.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.bookingForm.additionalFields && self.bookingForm.additionalFields.count) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:BookingFormAdditionalFieldsSection]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - KVO

- (void)addObservers
{
    [self.bookingForm addObserver:self forKeyPath:@"eventID" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"unitID" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"client" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"startDate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"startTime" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"endTime" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"additionalFields" options:0 context:NULL];
    [self.bookingForm addObserver:self forKeyPath:@"locationID" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"getWorkDaysTimesRequest" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"locations" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    self.observing = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([keyPath isEqualToString:@"eventID"]) {
                if (self.services[self.bookingForm.eventID].unitMap) {
                    NSDictionary *unitMap = self.services[self.bookingForm.eventID].unitMap;
                    if (self.bookingForm.unitID
                        && ![[unitMap allKeys] containsObject:self.bookingForm.unitID])
                    {
                        self.bookingForm.unitID = nil;
                    } else if ([unitMap allKeys].count == 1) {
                        self.bookingForm.unitID = [[unitMap allKeys] firstObject];
                    }
                }
                [self loadAdditionalFields];
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormServiceField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([keyPath isEqualToString:@"unitID"]) {
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormPerformerField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                if (self.bookingForm.eventID && ![self performerWithID:self.bookingForm.unitID canPerformServiceWithID:self.bookingForm.eventID]) {
                    [self.bookingForm setEventID:nil withDuration:0];
                }
                if (self.bookingForm.locationID) {
                    NSDictionary *location = [self locationWithID:self.bookingForm.locationID];
                    if (location && ![location[@"units"] containsObject:self.bookingForm.unitID]) {
                        self.bookingForm.locationID = nil;
                    }
                }
            }
            else if ([keyPath isEqualToString:@"client"]) {
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormClientField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([keyPath isEqualToString:@"startDate"]) {
                if ([change[NSKeyValueChangeNewKey] isEqual:change[NSKeyValueChangeOldKey]]) {
                    return ; // nothing to do
                }
                self.bookingForm.startTime = nil;
                self.bookingForm.endTime = nil;
                [self loadWorkingHoursForStartDate];
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormStartDateField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
            else if ([keyPath isEqualToString:@"startTime"]) {
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormStartTimeField section:BookingFormGeneralSection],
                                                         [self viewIndexPathForRow:BookingFormStartDateField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([keyPath isEqualToString:@"endTime"]) {
                [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormEndTimeField section:BookingFormGeneralSection],
                                                         [self viewIndexPathForRow:BookingFormStartDateField section:BookingFormGeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([keyPath isEqualToString:@"getWorkDaysTimesRequest"]) {
                if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]] && [change[NSKeyValueChangeOldKey] isEqual:[NSNull null]]) {
                    return ; // nothing to do: same value as it was.
                }
                if (([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]] && ![change[NSKeyValueChangeOldKey] isEqual:[NSNull null]])
                    || (![change[NSKeyValueChangeNewKey] isEqual:[NSNull null]] && [change[NSKeyValueChangeOldKey] isEqual:[NSNull null]]))
                {
                    [self.tableView reloadRowsAtIndexPaths:@[[self viewIndexPathForRow:BookingFormStartTimeField section:BookingFormGeneralSection],
                                                             [self viewIndexPathForRow:BookingFormStartDateField section:BookingFormGeneralSection],
                                                             [self viewIndexPathForRow:BookingFormEndTimeField section:BookingFormGeneralSection]]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else if ([keyPath isEqualToString:@"additionalFields"]) {
                if (self.bookingForm.additionalFields.count) {
                    [self.additionalFieldsDS setAdditionalFields:self.bookingForm.additionalFields];
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:BookingFormAdditionalFieldsSection] withRowAnimation:UITableViewRowAnimationTop];
                }
            }
            else if ([keyPath isEqualToString:@"locationID"]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:BookingFormLocationSection]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([keyPath isEqualToString:@"locations"]) {
                if ([change[NSKeyValueChangeOldKey] isEqual:[NSNull null]]) {
                    if (self.locations.count > 0) {
                        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:BookingFormLocationSection] withRowAnimation:UITableViewRowAnimationTop];
                    }
                } else {
                    if (self.locations.count > 0) {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:BookingFormLocationSection] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)removeObservers
{
    if (self.observing) {
        [self.bookingForm removeObserver:self forKeyPath:@"eventID" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"unitID" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"client" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"startDate" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"startTime" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"endTime" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"additionalFields" context:NULL];
        [self.bookingForm removeObserver:self forKeyPath:@"locationID" context:NULL];
        [self removeObserver:self forKeyPath:@"getWorkDaysTimesRequest" context:NULL];
        [self removeObserver:self forKeyPath:@"locations" context:NULL];
        self.observing = NO;
    }
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark - Getters

- (NSDateFormatter *)timeFormatter
{
    if (_timeFormatter) {
        return _timeFormatter;
    }
    _timeFormatter = [NSDateFormatter new];
    [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    return _timeFormatter;
}

- (NSDateIntervalFormatter *)intervalFormatter
{
    if (_intervalFormatter) {
        return _intervalFormatter;
    }
    _intervalFormatter = [NSDateIntervalFormatter new];
    [_intervalFormatter setDateStyle:NSDateIntervalFormatterMediumStyle];
    [_intervalFormatter setTimeStyle:NSDateIntervalFormatterNoStyle];
    return _intervalFormatter;
}

#pragma mark - Server Requests

- (void)loadWorkingHoursForStartDate
{
    if (self.getWorkDaysTimesRequest) {
        [[SBSession defaultSession] cancelRequestWithID:self.getWorkDaysTimesRequest.GUID];
    }
    [self.hoursSelectorDataSource setWorkingHoursMatrix:nil
                                               recordID:(self.bookingForm.unitID ? self.bookingForm.unitID : @"")];
    self.getWorkDaysTimesRequest = [[SBSession defaultSession] getWorkDaysTimesForDate:self.bookingForm.startDate
                                                                    callback:^(SBResponse *response)
                                                                    {
                                                                        self.getWorkDaysTimesRequest = nil;
                                                                        if (!response.error) {
                                                                            NSAssert(self.timeFrameStep != 0, @"time frame not configured");
                                                                            [pendingRequests removeObject:response.requestGUID];
                                                                            SBWorkingHoursMatrix *matrix = [[SBWorkingHoursMatrix alloc] initWithData:response.result
                                                                                                                                              forDate:self.bookingForm.startDate
                                                                                                                                                 step:self.timeFrameStep];
                                                                            self.hoursSelectorDataSource.timeFrameStep = self.timeFrameStep;
                                                                            if (self.bookingForm.unitID) {
                                                                                [self.hoursSelectorDataSource setWorkingHoursMatrix:matrix
                                                                                                                           recordID:self.bookingForm.unitID];
                                                                            }
                                                                            else {
                                                                                [self.hoursSelectorDataSource setWorkingHoursMatrix:matrix
                                                                                                                           recordID:kSBWorkingHoursMatrixDefaultRecordID];
                                                                            }
                                                                            if (!self.bookingForm.startTime) {
                                                                                if (self.preferedStartTime) {
                                                                                    self.bookingForm.startTime = self.preferedStartTime;
                                                                                }
                                                                                else if (self.hoursSelectorDataSource.hours.count > 0) {
                                                                                    self.bookingForm.startTime = self.hoursSelectorDataSource.hours.firstObject;
                                                                                }
                                                                            }
                                                                            // use sync method to sync number of rows which can be changed by statusesCollection
                                                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                                                                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:BookingFormStartTimeField
                                                                                                                                            inSection:BookingFormGeneralSection],
                                                                                                                         [NSIndexPath indexPathForRow:BookingFormEndTimeField
                                                                                                                                            inSection:BookingFormGeneralSection]]
                                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                            });
                                                                        }
                                                                    }];
    [pendingRequests addObject:self.getWorkDaysTimesRequest.GUID];
    [[SBSession defaultSession] performReqeust:self.getWorkDaysTimesRequest];
}

- (void)loadAdditionalFields
{
    self.getAdditionalFieldsRequest = [[SBSession defaultSession] getAdditionalFieldsForEvent:self.bookingForm.eventID callback:^(SBResponse <NSArray *> *response) {
        [pendingRequests removeObject:response.requestGUID];
        self.getAdditionalFieldsRequest = nil;
        if (response.error) {
            if (!response.canceled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideFooterActivityIndicator];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:NSLS(@"Information about additional fields for this service not loaded. Without this information booking cannot be completed. Please try again.",@"")
                                                                   delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFooterActivityIndicator];
            });
            NSMutableArray <SBAdditionalField *> *loadedFields = [[NSMutableArray alloc] initWithArray:response.result copyItems:YES];
            if (self.additionalFieldsPreset) {
                [loadedFields enumerateObjectsUsingBlock:^(SBAdditionalField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSUInteger index = [self.additionalFieldsPreset indexOfObjectPassingTest:^BOOL(SBBookingInfoAdditionalField * _Nonnull fld, NSUInteger idx, BOOL * _Nonnull stop) {
                        *stop = [fld.name isEqualToString:obj.name];
                        return *stop;
                    }];
                    if (index != NSNotFound) {
                        SBBookingInfoAdditionalField *presetField = self.additionalFieldsPreset[index];
                        obj.value = presetField.value;
                    }
                }];
            }
            // sync additional fields to prevent crash on sections reload
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.bookingForm.additionalFields = loadedFields;
            });
        }
    }];
    [pendingRequests addObject:self.getAdditionalFieldsRequest.GUID];
    if (self.bookingForm.additionalFields && self.bookingForm.additionalFields.count) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:BookingFormAdditionalFieldsSection];
        self.bookingForm.additionalFields = nil;
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self showFooterActivityIndicator];
    [[SBSession defaultSession] performReqeust:self.getAdditionalFieldsRequest];
}

- (void)loadLocations
{
    if (self.getLocationsRequest) {
        return;
    }
    self.getLocationsRequest = [[SBSession defaultSession] getLocationsWithCallback:^(SBResponse<NSArray <NSDictionary *> *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        self.getLocationsRequest = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideFooterActivityIndicator];
        });
        if (response.error && !response.canceled) {
            // do nothing: booking without location still possible
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
//                                                                               message:NSLS(@"Information about locations not loaded.",@"")
//                                                                        preferredStyle:UIAlertControllerStyleAlert];
//                [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }]];
//                [self presentViewController:alert animated:YES completion:nil];
//            });
        } else {
            // sync locations to prevent crash on sections reload
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.locations = response.result;
                if (!self.bookingForm.locationID || [self.bookingForm.locationID isEqualToString:@""]) {
                    [self.locations enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj[@"is_default"] boolValue]) {
                            self.bookingForm.locationID = obj[@"id"];
                            *stop = YES;
                        }
                    }];
                }
            });
        }
    }];
    [pendingRequests addObject:self.getLocationsRequest.GUID];
    [self showFooterActivityIndicator];
    [[SBSession defaultSession] performReqeust:self.getLocationsRequest];
}

- (void)makeBookingRequest
{
    [self removeObservers];
    SBRequestCallback callbak = ^(SBResponse <NSDictionary *> *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (response.error) {
            if (!response.canceled) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addObservers];
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    self.activityIndicator.hidden = YES;
                    NSString *message = [response.error message];
                    if ([response.error.domain isEqualToString:SBServerErrorDomain]) {
                        switch (response.error.code) {
                            case SB_SERVER_ERROR_DATE_VALUE:
                            case SB_SERVER_ERROR_TIME_VALUE:
                            {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                                message:NSLS(@"Oops, seems this time is not available. Probably the provider is occupied with some other client. Please try a different time.",@"")
                                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                                      otherButtonTitles:nil];
                                [alert show];
                            }
                                return;
                            case SB_SERVER_ERROR_EVENT_ID_VALUE:
                            case SB_SERVER_ERROR_UNIT_ID_VALUE:
                            case SB_SERVER_ERROR_CLIENT_NAME_VALUE:
                            case SB_SERVER_ERROR_CLIENT_EMAIL_VALUE:
                            case SB_SERVER_ERROR_CLIENT_PHONE_VALUE:
                            case SB_SERVER_ERROR_CLIENT_ID:
                            case SB_SERVER_ERROR_ADDITIONAL_FIELDS:
                                message = NSLS(@"Not valid booking data. Please check all form fields and try again.", @"");
                            default:
                                break;
                        }
                    }
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:message delegate:nil
                                                          cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                    [alert show];
                });

            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                NSDictionary *bookingData = [response.result[@"bookings"] firstObject];
                NSNumber *pluginStatus = [[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryStatusPlugin];
                if (bookingData && bookingData[@"id"] && pluginStatus != nil && pluginStatus.boolValue) {
                    [self makeSetStatusRequestForBooking:bookingData[@"id"]];
                }
                else {
                    [self invalidateCaches];
                    if (self.bookingCreatedHandler) {
                        self.bookingCreatedHandler(self);
                    }
                }
            });
        }
    };
    if (self.bookingForm.bookingID) {
        SBRequest *editBookingRequest = [[SBSession defaultSession] editBooking:self.bookingForm callback:callbak];
        [pendingRequests addObject:editBookingRequest.GUID];
        [[SBSession defaultSession] performReqeust:editBookingRequest];
    }
    else {
        SBRequest *createBookingRequest = [[SBSession defaultSession] book:self.bookingForm callback:callbak];
        [pendingRequests addObject:createBookingRequest.GUID];
        [[SBSession defaultSession] performReqeust:createBookingRequest];
    }
    self.activityIndicator.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)makeSetStatusRequestForBooking:(NSString *)bookingID
{
    if (!self.bookingStatus && !self.statusesCollection.defaultStatus) {
        return; // nothing to do here
    }
    SBBookingStatus *status = (self.bookingStatus ? self.bookingStatus : self.statusesCollection.defaultStatus);
    SBRequest *request = [[SBSession defaultSession] setStatus:status.statusID forBooking:bookingID
                                                      callback:^(SBResponse<NSNumber *> * _Nonnull response)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (response.error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Warning",@"")
                                                                message:NSLS(@"An error occurred during status change for booking.",@"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                [alert show];
            }
            [self invalidateCaches];
            self.activityIndicator.hidden = YES;
            if (self.bookingCreatedHandler) {
                self.bookingCreatedHandler(self);
            }
        });
    }];
    [pendingRequests addObject:request.GUID];
    self.activityIndicator.hidden = NO;
    [[SBSession defaultSession] performReqeust:request];
}

- (void)invalidateCaches
{
    if (self.bookingForm.bookingID) {
        SBGetBookingDetailsRequest *getBookingDetailsRequest = [SBGetBookingDetailsRequest new];
        getBookingDetailsRequest.bookingID = self.bookingForm.bookingID;
        [[SBCache cache] invalidateCacheForRequest:getBookingDetailsRequest];
    }
    [[SBCache cache] invalidateCacheForRequestClass:[SBGetBookingsRequest class]];
}

#pragma mark - Actions

- (IBAction)doneAction:(id)sender
{
    SBUser *user = [[SBSession defaultSession] user];
    NSAssert(user != nil, @"no user");
    if (self.bookingForm.bookingID) {
        if (([self.bookingForm.unitID isEqualToString:user.associatedPerformerID] && ![user hasAccessToACLRule:SBACLRuleEditOwnBooking])
            || (![self.bookingForm.unitID isEqualToString:user.associatedPerformerID] && ![user hasAccessToACLRule:SBACLRuleEditBooking]))
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Access denied",@"")
                                                            message:NSLS(@"You have no permissions to edit this booking.",@"")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLS(@"OK",@"")
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    } else if (![user hasAccessToACLRule:SBACLRuleCreateBooking] || (![user.associatedPerformerID isEqualToString:self.bookingForm.unitID] && ![user hasAccessToACLRule:SBACLRulePerformersFullListAccess])) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Access denied",@"")
                                                        message:NSLS(@"You have no permissions to add bookings.",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLS(@"OK",@"")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (self.getAdditionalFieldsRequest) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Booking data not valid.",@"")
                                                        message:NSLS(@"Information about additional fields not loaded. Without it booking cannot be completed.",@"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLS(@"OK",@"")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    if (pendingRequests.count) {
        [[SBSession defaultSession] cancelRequests:pendingRequests];
    }
    if (self.getWorkDaysTimesRequest) {
        [[SBSession defaultSession] cancelRequestWithID:self.getWorkDaysTimesRequest.GUID];
        self.getWorkDaysTimesRequest = nil;
    }
    NSString *bookingDataValidationMessage = nil;
    for (SBAdditionalField *additionalField in self.bookingForm.additionalFields) {
        if (![additionalField isValid]) {
            bookingDataValidationMessage = [NSString stringWithFormat:NSLS(@"Please set valid value for additional field %@.",@""), additionalField.title];
            break;
        }
    }
    SBValidator *serverIDValidator = [SBServerIDValidator new];
    if (![serverIDValidator isValid:self.bookingForm.eventID]) {
        bookingDataValidationMessage = NSLS(@"Please select service.",@"");
    }
    if (![serverIDValidator isValid:self.bookingForm.unitID]) {
        bookingDataValidationMessage = NSLS(@"Please select performer.",@"");
    }
    if (!self.bookingForm.startDate || !self.bookingForm.startTime) {
        bookingDataValidationMessage = NSLS(@"Please select start date and time.",@"");
    }
    if (!self.bookingForm.endTime) {
        bookingDataValidationMessage = NSLS(@"Please select ent time.",@"");
    }
    
    if (bookingDataValidationMessage) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Booking data not valid.",@"")
                                                                       message:bookingDataValidationMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *bookingWarningMessage = nil;
    if (![serverIDValidator isValid:self.bookingForm.client[@"id"]]) {
        // it is possible to create a booking without client (for admin only) but show warning
        bookingWarningMessage = NSLS(@"Client not selected. Do you want to make this appointment without client?", @"");
    }
    if (IsLocationsEnabled && (!self.bookingForm.locationID || [self.bookingForm.locationID isEqualToString:@""])) {
        bookingWarningMessage = NSLS(@"Location not selected. Do you want to make this appointment without location?", @"");
    }
    if (bookingWarningMessage) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLS(@"Warning", @"")
                                                                                 message:bookingWarningMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLS(@"NO",@"") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLS(@"YES",@"")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self makeBookingRequest];
                                                          }]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    [self makeBookingRequest];
}

- (IBAction)cancelAction:(id)sender
{
    [self removeObservers];
    if (pendingRequests.count) {
        [[SBSession defaultSession] cancelRequests:pendingRequests];
    }
    if (self.getWorkDaysTimesRequest) {
        [[SBSession defaultSession] cancelRequestWithID:self.getWorkDaysTimesRequest.GUID];
        self.getWorkDaysTimesRequest = nil;
    }
    if (self.bookingCanceledHandler) {
        self.bookingCanceledHandler(self);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didSelectDateAction:(UIDatePicker *)sender
{
    if (self.pickerIndexPath.row == BookingFormStartDateField) {
        if ([sender.date compare:sender.minimumDate] != NSOrderedAscending) {
            [self.bookingForm setStartDate:sender.date];
        }
    } else {
        NSAssertFail();
    }
}

#pragma mark -

- (BOOL)performerWithID:(NSString *)performerID canPerformServiceWithID:(NSString *)serviceID
{
    NSParameterAssert(performerID != nil);
    NSParameterAssert(serviceID != nil);
    NSAssert(self.services[serviceID] != nil, @"unexpected service id (%@).", serviceID);
    NSAssert(self.performers[performerID] != nil, @"unexpected service id (%@).", performerID);
    if (self.services[serviceID].unitMap) {
        return [[self.services[serviceID].unitMap allKeys] containsObject:performerID];
    }
    return YES;
}

- (nullable NSDictionary <NSString *, NSObject *> *)locationWithID:(NSString *)locationID
{
    if (!IsLocationsEnabled) {
        return nil;
    }
    NSUInteger index = [self.locations indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"id"] isEqualToString:locationID];
    }];
    if (index != NSNotFound) {
        return self.locations[index];
    }
    return nil;
}

#pragma mark - UI Helpers

- (void)showFooterActivityIndicator
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator startAnimating];
    self.tableView.tableFooterView = activityIndicator;
}

- (void)hideFooterActivityIndicator
{
    if (self.getLocationsRequest == nil && self.getAdditionalFieldsRequest == nil) {
        self.tableView.tableFooterView = nil;
    }
}

- (BOOL)isPickerVisible
{
    return self.pickerIndexPath != nil;
}

- (NSIndexPath *)modelIndexPathForRow:(NSInteger)row section:(NSInteger)section
{
    if ([self isPickerVisible] && row > self.pickerIndexPath.row) {
        return [NSIndexPath indexPathForRow:row-1 inSection:section];
    } else {
        return [NSIndexPath indexPathForRow:row inSection:section];
    }
}

- (NSIndexPath *)viewIndexPathForRow:(NSInteger)row section:(NSInteger)section
{
    if ([self isPickerVisible] && row > self.pickerIndexPath.row) {
        return [NSIndexPath indexPathForRow:row+1 inSection:section];
    } else {
        return [NSIndexPath indexPathForRow:row inSection:section];
    }
}

- (NSInteger)pickerCellRowIndex
{
    if ([self isPickerVisible] &&
        (self.pickerIndexPath.row == BookingFormStartDateField
        || self.pickerIndexPath.row == BookingFormStartTimeField
        || self.pickerIndexPath.row == BookingFormEndTimeField
        || self.pickerIndexPath.row == BookingFormStatusField))
    {
        return self.pickerIndexPath.row + 1;
    }
    return NSNotFound;
}

- (NSIndexPath *)correctPickerViewIndexPath
{
    if (self.pickerIndexPath.row == BookingFormStartDateField
        || self.pickerIndexPath.row == BookingFormStartTimeField
        || self.pickerIndexPath.row == BookingFormEndTimeField
        || self.pickerIndexPath.row == BookingFormStatusField)
    {
        return [NSIndexPath indexPathForRow:[self pickerCellRowIndex] inSection:self.pickerIndexPath.section];
    }
    return nil;
}

- (void)showPickerForIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    if (![self isPickerVisible] || ![self.pickerIndexPath isEqual:indexPath]) {
        [self.tableView beginUpdates];
        if ([self isPickerVisible]) {
            [self.tableView deleteRowsAtIndexPaths:@[[self correctPickerViewIndexPath]] withRowAnimation:UITableViewRowAnimationTop];
        }
        self.pickerIndexPath = [self modelIndexPathForRow:indexPath.row section:indexPath.section];
        [self.tableView insertRowsAtIndexPaths:@[[self correctPickerViewIndexPath]]
                              withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    }
}

- (void)hidePicker
{
    NSIndexPath *pickerViewIndexPath = [self correctPickerViewIndexPath];
    if (pickerViewIndexPath) {
        self.pickerIndexPath = nil;
        [self.tableView deleteRowsAtIndexPaths:@[pickerViewIndexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark - Table view DadaSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return BookingFormAdditionalFieldsSection + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == BookingFormGeneralSection) {
        NSInteger rowsCount = BookingFormEndTimeField + 1;
        if (self.statusesCollection && self.statusesCollection.count > 0) {
            rowsCount++;
        }
        if ([self isPickerVisible]) {
            rowsCount++;
        }
        return rowsCount;
    }
    else if (IsLocationsEnabled && section == BookingFormLocationSection) {
        return 1;
    }
    else if (IsAdditionalFieldsEnabled && section == BookingFormAdditionalFieldsSection) {
        return self.bookingForm.additionalFields.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self pickerCellRowIndex] == indexPath.row) {
        if (self.pickerIndexPath.row == BookingFormStartDateField) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UIDatePickerViewCell"];
            UIDatePicker *datePicker = (UIDatePicker *)[cell viewWithTag:kControlTag];
            datePicker.minimumDate = [NSDate date];
            datePicker.date = self.bookingForm.startDate;
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UIPickerViewCell"];
            UIPickerView *picker = (UIPickerView *)[cell viewWithTag:kControlTag];
            if (self.pickerIndexPath.row == BookingFormStartTimeField) {
                picker.dataSource = self.hoursSelectorDataSource;
                NSInteger row = [self.hoursSelectorDataSource.hours indexOfObject:self.bookingForm.startTime];
                [picker selectRow:(row != NSNotFound ? row : 0) inComponent:0 animated:NO];
                [self.hoursSelectorDataSource setStartHoursModeWithStartHour:self.bookingForm.startTime];
            } else if (self.pickerIndexPath.row == BookingFormEndTimeField) {
                picker.dataSource = self.hoursSelectorDataSource;
                NSInteger row = [self.hoursSelectorDataSource.hours indexOfObject:self.bookingForm.endTime];
                [picker selectRow:(row != NSNotFound ? row : 0) inComponent:0 animated:NO];
                [self.hoursSelectorDataSource setEndHoursModeWithEndHour:self.bookingForm.endTime];
            } else if (self.pickerIndexPath.row == BookingFormStatusField) {
                picker.dataSource = self.statusesCollection;
                SBBookingStatus *status = (self.bookingStatus ? self.bookingStatus : self.statusesCollection.defaultStatus);
                [picker selectRow:[self.statusesCollection indexForObject:status] inComponent:0 animated:NO];
            }
            picker.delegate = self;
            return cell;
        }
    }
    else if (indexPath.section == BookingFormGeneralSection) {
        ACHRightDetailsTableViewCell *cell = (ACHRightDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        switch ([[self modelIndexPathForRow:indexPath.row section:indexPath.section] row]) {
            case BookingFormClientField:
                cell.keyLabel.text = NSLS(@"Client:",@"");
                cell.valueLabel.text = (self.bookingForm.client ? self.bookingForm.client[@"name"] : @"...");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case BookingFormStartDateField:
                cell.keyLabel.text = NSLS(@"Date:",@"");
                if (!self.bookingForm.startTime || !self.bookingForm.endTime) {
                    cell.valueLabel.text = [self.intervalFormatter stringFromDate:self.bookingForm.startDate toDate:self.bookingForm.startDate];
                }
                else {
                    cell.valueLabel.text = [self.intervalFormatter stringFromDate:self.bookingForm.startTime toDate:self.bookingForm.endTime];
                }
                [cell.contentView setNeedsDisplay];
                [cell.contentView setNeedsLayout];
                break;
            case BookingFormStartTimeField:
                cell.keyLabel.text = NSLS(@"Start Time:",@"");
                if (self.hoursSelectorDataSource.hours.count == 0 || !self.bookingForm.startTime) {
                    if (self.getWorkDaysTimesRequest) {
                        cell.valueLabel.text = @"";
                        cell.activityIndicator.hidden = NO;
                    } else {
                        cell.valueLabel.text = @"--";
                    }
                } else {
                    cell.valueLabel.text = [self.timeFormatter stringFromDate:self.bookingForm.startTime];
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            case BookingFormEndTimeField:
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.keyLabel.text = NSLS(@"End Time:",@"");
                if (self.hoursSelectorDataSource.hours.count == 0 || !self.bookingForm.endTime) {
                    if (self.getWorkDaysTimesRequest) {
                        cell.valueLabel.text = @"";
                        cell.activityIndicator.hidden = NO;
                    } else {
                        cell.valueLabel.text = @"--";
                    }
                }
                else {
                    cell.valueLabel.text = [self.timeFormatter stringFromDate:self.bookingForm.endTime];
                }
                break;
            case BookingFormServiceField:
                cell.keyLabel.text = NSLS(@"Service:",@"");
                if (self.bookingForm.eventID) {
                    if (self.services && self.services[self.bookingForm.eventID]) {
                        cell.valueLabel.text = self.services[self.bookingForm.eventID].name;
                    } else if (self.serviceName) {
                        cell.valueLabel.text = self.serviceName;
                    } else {
                        cell.valueLabel.text = @"...";
                    }
                } else {
                    cell.valueLabel.text = @"...";
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case BookingFormPerformerField:
                cell.keyLabel.text = NSLS(@"Provider:",@"");
                if (self.bookingForm.unitID) {
                    if (self.performers && self.performers[self.bookingForm.unitID]) {
                        SBPerformer *performer = self.performers[self.bookingForm.unitID];
                        UIColor *color = performer.colorObject;
                        if (color) {
                            NSString *string = [NSString stringWithFormat:@"• %@", performer.name];
                            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
                            [attributedString addAttributes:@{NSForegroundColorAttributeName: color} range:NSMakeRange(0, @"•".length)];
                            cell.valueLabel.attributedText = attributedString;
                        } else {
                            cell.valueLabel.text = performer.name;
                        }
                    } else if (self.performerName) {
                        cell.valueLabel.text = self.performerName;
                    } else {
                        cell.valueLabel.text = @"...";
                    }
                } else {
                    cell.valueLabel.text = @"...";
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case BookingFormStatusField:
                cell.keyLabel.text = NSLS(@"Status:",@"");
                if (self.bookingStatus) {
                    cell.valueLabel.attributedText = [self.statusesCollection attributedTitleForStatus:self.bookingStatus];
                }
                else if (self.statusesCollection.defaultStatus) {
                    cell.valueLabel.attributedText = [self.statusesCollection attributedTitleForStatus:self.statusesCollection.defaultStatus];
                }
                else {
                    cell.valueLabel.text = @"...";
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
//            default:
//                NSAssert(NO, @"unexpected booking form field");
        }
        return cell;
    }
    else if (IsLocationsEnabled && indexPath.section == BookingFormLocationSection) {
        ACHRightDetailsTableViewCell *cell = (ACHRightDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.keyLabel.text = NSLS(@"Location:",@"");
        if (self.bookingForm.locationID) {
            NSDictionary *location = [self locationWithID:self.bookingForm.locationID];
            if (location) {
                cell.valueLabel.text = location[@"title"];
            } else {
                cell.valueLabel.text = @"...";
            }
        } else {
            cell.valueLabel.text = @"...";
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    else if (IsAdditionalFieldsEnabled && indexPath.section == BookingFormAdditionalFieldsSection) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.additionalFieldsDS.cellReuseIdentifier forIndexPath:indexPath];
        [self.additionalFieldsDS configureCell:cell forRowAtIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([pendingRequests count]) {
        return;
    }
    if ([self.pickerIndexPath isEqual:indexPath]) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self hidePicker];
        return;
    }
    if (IsAdditionalFieldsEnabled && indexPath.section == BookingFormAdditionalFieldsSection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SBAdditionalField *field = self.bookingForm.additionalFields[indexPath.row];
        ACHAdditionalFieldEditorController *controller = [ACHAdditionalFieldEditorController editControllerForField:field];
        if (controller) {
            [self.navigationController pushViewController:controller animated:YES];
        }
        return;
    }
    if (indexPath.section == BookingFormGeneralSection) {
        switch ([[self modelIndexPathForRow:indexPath.row section:indexPath.section] row]) {
            case BookingFormClientField:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self performSegueWithIdentifier:@"selectClient" sender:self];
                break;
            case BookingFormServiceField:
            case BookingFormPerformerField:
                if ([self isPickerVisible]) {
                    [self hidePicker];
                }
                [self performSegueWithIdentifier:@"selector" sender:self];
                break;
            case BookingFormStartTimeField:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                if (self.hoursSelectorDataSource.hours.count == 0) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:NSLS(@"No working hours for selected start date",@"")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles: nil];
                    [alert show];
                }
                else {
                    [self showPickerForIndexPath:indexPath];
                }
                break;
            case BookingFormEndTimeField:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                if (self.hoursSelectorDataSource.hours.count == 0) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:NSLS(@"No working hours for selected end date",@"")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles: nil];
                    [alert show];
                }
                else {
                    [self showPickerForIndexPath:indexPath];
                }
                break;
            case BookingFormStatusField:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self showPickerForIndexPath:indexPath];
                break;
            case BookingFormStartDateField:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self showPickerForIndexPath:indexPath];
                break;
                
            default:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                if ([self isPickerVisible]) {
                    [self hidePicker];
                }
                break;
        }
    }
    if (IsLocationsEnabled && indexPath.section == BookingFormLocationSection) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self performSegueWithIdentifier:@"selectLocation" sender:self];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (IsAdditionalFieldsEnabled && section == BookingFormAdditionalFieldsSection) {
        return NSLS(@"Additional Fields",@"");
    }
    return nil;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selector"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSParameterAssert(indexPath != nil);
        FilterListSelectorViewController *controller = (FilterListSelectorViewController *) segue.destinationViewController;
        controller.filterListSelectorDelegate = self;
        if (indexPath.row == BookingFormServiceField) {
            if (self.bookingForm.unitID) {
                controller.collection = [self.services collectionWithObjectsPassingTest:^BOOL(SBService * _Nonnull service, NSUInteger idx, BOOL * _Nonnull stop) {
                    return service.unitMap ? [[service.unitMap allKeys] containsObject:self.bookingForm.unitID] : YES;
                }];
            }
            else {
                controller.collection = self.services;
            }
        }
        else if (indexPath.row == BookingFormPerformerField) {
            if (self.bookingForm.eventID && self.services[self.bookingForm.eventID].unitMap) {
                SBService *event = self.services[self.bookingForm.eventID];
                controller.collection = [self.performers collectionWithObjectsPassingTest:^BOOL(SBPerformer * _Nonnull performer, NSUInteger idx, BOOL * _Nonnull stop) {
                    return [[event.unitMap allKeys] containsObject:performer.performerID];
                }];
            } else {
                controller.collection = self.performers;
            }
        }
    }
    else if ([segue.identifier isEqualToString:@"selectClient"]) {
        ClientListViewController *controller = (ClientListViewController *) segue.destinationViewController;
        controller.clientSelectedHandler = ^(NSDictionary *client) {
            self.bookingForm.client = client;
            [self.navigationController popToViewController:self animated:YES];
        };
    }
    else if ([segue.identifier isEqualToString:@"selectLocation"]) {
        LocationsListViewController *controller = (LocationsListViewController *) segue.destinationViewController;
        if (self.bookingForm.unitID) {
            controller.unitID = self.bookingForm.unitID;
        }
        controller.locationSelectedHandler = ^(NSDictionary *location) {
            self.bookingForm.locationID = location[@"id"];
            [self.navigationController popToViewController:self animated:YES];
        };
    }
}

#pragma mark - UIPickerView delegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (self.pickerIndexPath.section == BookingFormGeneralSection) {
        if (self.pickerIndexPath.row == BookingFormStartTimeField || self.pickerIndexPath.row == BookingFormEndTimeField) {
            return [self.hoursSelectorDataSource pickerView:pickerView attributedTitleForRow:row forComponent:component];
        }
        else if (self.pickerIndexPath.row == BookingFormStatusField) {
            return [self.statusesCollection pickerView:pickerView attributedTitleForRow:row forComponent:component];
        }
    }
    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.pickerIndexPath.row == BookingFormStartTimeField) {
        self.bookingForm.startTime = self.hoursSelectorDataSource.hours[row];
    }
    else if (self.pickerIndexPath.row == BookingFormEndTimeField) {
        NSDate *oldValue = self.bookingForm.endTime;
        self.bookingForm.endTime = self.hoursSelectorDataSource.hours[row];
        if ([self.bookingForm.startTime compare:self.bookingForm.endTime] != NSOrderedAscending) {
            self.bookingForm.endTime = oldValue;
            if ([self.hoursSelectorDataSource.hours indexOfObject:oldValue] == NSNotFound) {
                self.bookingForm.endTime = [self.bookingForm validEndTime];
            }
            if ([self.hoursSelectorDataSource.hours indexOfObject:self.bookingForm.endTime] != NSNotFound) {
                [pickerView selectRow:[self.hoursSelectorDataSource.hours indexOfObject:self.bookingForm.endTime]
                          inComponent:component animated:YES];
            }
        }
    }
    else if (self.pickerIndexPath.row == BookingFormStatusField) {
        self.bookingStatus = self.statusesCollection[row];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:BookingFormStatusField inSection:BookingFormGeneralSection]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self hidePicker];
}

#pragma mark - Filter List Selector Delegate

- (NSString *)titleForAnyItemInFilterListSelector:(FilterListSelectorViewController *)selector
{
    return nil;
}

- (BOOL)isAnyItemEnabledForFilterListSelector:(FilterListSelectorViewController *)selector
{
    return NO;
}

- (void)filterListSelector:(FilterListSelectorViewController *)selector didSelectItem:(nullable NSObject<FilterListSelectorItemProtocol> *)item
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSParameterAssert(indexPath != nil);
    if (!indexPath) {
        return;
    }
    if (indexPath.row == BookingFormPerformerField) {
        self.bookingForm.unitID = item.itemID;
    }
    else {
        SBService *service = (SBService *)item;
        [self.bookingForm setEventID:item.itemID withDuration:[service.duration integerValue]];
        self.bookingForm.endTime = [self.bookingForm.startTime dateByAddingTimeInterval:(self.bookingForm.eventDuration * 60)];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)filterListSelectorWillDisappear:(FilterListSelectorViewController *)selector
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (!indexPath) {
        return;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
