//
//  SBSession.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSession.h"
#import "SBSessionManager.h"
#import "SBGetBookingsRequest.h"
#import "SBGetCompanyInfo.h"
#import "SBGetUnitWorkdayInfoRequest.h"
#import "SBGetBookingDetailsRequest.h"
#import "SBCancelBookingRequest.h"
#import "SBGetUnitListRequest.h"
#import "SBGetEventListRequest.h"
#import "SBGetUserTokenRequest.h"
#import "SBGetClientListRequest.h"
#import "SBGetClientRequest.h"
#import "SBAddClientRequest.h"
#import "SBGetAdditionalFieldsRequest.h"
#import "SBBookRequest.h"
#import "SBAddDeviceTokenRequest.h"
#import "SBDeleteDeviceToken.h"
#import "SBEditBookRequest.h"
#import "SBGetStatusesRequest.h"
#import "SBGetWorkDaysTimesRequest.h"
#import "NSDate+TimeManipulation.h"
#import "SBGetWorkloadRequest.h"
#import "SBGetCurrentTariffInfoRequest.h"
#import "SBGetTopPerformersRequest.h"
#import "SBGetTopServicesRequest.h"
#import "SBGetBookingCancellationsInfoRequest.h"
#import "SBGetVisitorStatsRequest.h"
#import "SBGetBookingStatsRequest.h"
#import "SBIsPluginActivatedRequest.h"
#import "SBSetStatusRequest.h"
#import "SBPluginApproveBookingApproveRequest.h"
#import "SBPluginApproveBookingCancelRequest.h"
#import "SBPluginApproveGetPendingBookingsCountRequest.h"
#import "SBPluginApproveGetPendingBookingsRequest.h"
#import "SBPluginsRepository.h"
#import "SBGetCompanyParamRequest.h"
#import "SBGetGoogleCalendarBusyTimeRequest.h"
#import "SBGetLocationsListRequest.h"

#define SBSessionStorageKeyForCompanyLogin(companyLogin) ([NSString stringWithFormat:@"SBSessionStorageKey-%@", (companyLogin)])
#define SBSessionStorageKeyForDomainString(companyLogin) ([NSString stringWithFormat:@"SBSessionStorageKeyForDomainString-%@", (companyLogin)])

NSString * const kSBPendingBookings_DidUpdateNotification = @"kSBPendingBookings_DidUpdateNotification";
NSString * const kSBPendingBookings_BookingIDKey = @"kSBPendingBookings_BookingIDKey";
NSString * const kSBPendingBookings_BookingsCountKey = @"kSBPendingBookings_BookingsCountKey";

NSString * const kSBTimePeriodWeek = @"kSBTimePeriodWeek";

@interface SBSession () <SBRequestDelegate>
{
    NSOperationQueue *queue;
}

@property (nonatomic, readwrite, strong) SBUser *user;
@property (nonatomic, copy) NSString *token;

@end

@implementation SBSession

+ (instancetype)defaultSession
{
    return [[SBSessionManager sharedManager] defaultSession];
}

- (instancetype)initWithUser:(SBUser *)user token:(NSString *)token domain:(NSString *)domain
{
    NSAssert(user != nil, @"no user login");
    NSAssert(token != nil, @"no token");
    NSAssert(![token isEqualToString:@""], @"no token");
    self = [super init];
    if (self) {
        self.token = token;
        self.user = user;
        [self writeTokenToStorage];
        queue = [NSOperationQueue new];
        if (domain && ![domain isEqualToString:@""]) {
            [SBRequestOperation setDomainString:domain];
            [[NSUserDefaults standardUserDefaults] setObject:domain forKey:SBSessionStorageKeyForDomainString(user.credentials.companyLogin)];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else if ([[NSUserDefaults standardUserDefaults] objectForKey:SBSessionStorageKeyForDomainString(user.credentials.companyLogin)]) {
            [SBRequestOperation setDomainString:[[NSUserDefaults standardUserDefaults] objectForKey:SBSessionStorageKeyForDomainString(user.credentials.companyLogin)]];
        }
    }
    return self;
}

- (void)invalidate
{
    [queue cancelAllOperations];
    self.token = nil;
    self.user = nil;
    [self writeTokenToStorage];
    [SBRequestOperation setDomainString:nil];
}

- (NSString *)companyLogin
{
    return self.user.credentials.companyLogin;
}

- (void)writeTokenToStorage
{
    [[NSUserDefaults standardUserDefaults] setObject:self.token forKey:SBSessionStorageKeyForCompanyLogin(self.companyLogin)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cancelRequestWithID:(NSString *)requestID
{
    for (SBRequest *operation in queue.operations) {
        if ([operation.GUID isEqualToString:requestID]) {
            [operation cancel];
        }
    }
}

- (void)cancelRequests:(NSArray *)requests
{
    for (SBRequest *operation in queue.operations) {
        if ([requests containsObject:operation.GUID]) {
            [operation cancel];
        }
    }
}

- (void)repeatRequest:(SBRequest *)request
{
    NSAssertNotImplemented();
}

- (BOOL)request:(SBRequest *)request didFinishWithResponse:(SBResponse *)response
{
    if ([response.error.domain isEqualToString:SBRequestErrorDomain] && response.error.code == SBInvalidAuthTokenErrorCode) {
        for (SBRequest *r in queue.operations) {
            if ([r isKindOfClass:[SBGetUserTokenRequest class]]) {
                return NO;
            }
        }
        SBGetUserTokenRequest *authRequest = [[SBGetUserTokenRequest alloc] initWithComanyLogin:self.companyLogin];
        authRequest.login = self.user.credentials.userLogin;
        authRequest.password = self.user.credentials.password;
        authRequest.callback = ^(SBResponse *authResponse) {
            if (!authResponse.error) {
                self.token = authResponse.result;
                [self writeTokenToStorage];
                NSArray<SBRequest *> *operations = queue.operations;
                [queue cancelAllOperations];
                SBRequest *copy = [request copyWithToken:self.token]; // request already not in queue
                [self performReqeust:copy];
                for (SBRequest *operation in operations) {
                    if (![operation isKindOfClass:[SBGetUserTokenRequest class]]) {
                        SBRequest *copy = [operation copyWithToken:self.token];
                        [self performReqeust:copy];
                    }
                }
            }
            else {
                [[SBSessionManager sharedManager] endSession:self];
            }
        };
        [queue addOperation:authRequest];
        return NO;
    }
    return YES;
}

- (void)performReqeust:(SBRequest *)request
{
    NSParameterAssert(request != nil);
    if ([request isKindOfClass:[SBIsPluginActivatedRequest class]]) {
        /**
         * if plugins repository alredy have information about plugin usage then return it 
         * immediately without making request.
         * Warning: SBPluginsRepository doesn't have expiration time for storage information like SBCache
         */
        SBIsPluginActivatedRequest *pluginCheckRequest = (SBIsPluginActivatedRequest *)request;
        NSNumber *pluginEnabled = [[SBPluginsRepository repository] isPluginEnabled:pluginCheckRequest.pluginName];
        if (pluginEnabled != nil) {
            if (request.predispatchBlock) {
                request.predispatchBlock(request);
            }
            request.callback([SBCachedResponse cachedResponseWithResult:pluginEnabled requestGUID:request.GUID]);
            [request cancel];
            return;
        }
    }
    request.delegate = self;
    [queue addOperation:request];
    [queue addOperations:request.dependencies waitUntilFinished:NO];
}

- (__kindof SBRequest *)buildRequest:(Class)requestClass callback:(SBRequestCallback)callback
{
    SBRequest *request = [[requestClass alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    return request;
}

#pragma mark -

- (SBRequest *)getBookingsWithFilter:(SBGetBookingsFilter *)filter callback:(SBRequestCallback)callback
{
    SBGetBookingsRequest *request = [[SBGetBookingsRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.filter = filter;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getCompanyInfoWithCallback:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetCompanyInfo class] callback:callback];
}

- (SBRequest *)getUnitWorkdayInfoForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate callback:(SBRequestCallback)callback
{
    SBGetUnitWorkdayInfoRequest *request = [[SBGetUnitWorkdayInfoRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    request.startDate = startDate;
    request.endDate = endDate;
    return request;
}

- (SBRequest *)getWorkDaysTimesForDate:(NSDate *)startDate callback:(SBRequestCallback)callback
{
    SBGetWorkDaysTimesRequest *request = [[SBGetWorkDaysTimesRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    request.startDate = startDate;
    request.endDate = [startDate nextDayDate];
    return request;
}

- (SBRequest *)getWorkDaysTimesForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate callback:(SBRequestCallback)callback
{
    SBGetWorkDaysTimesRequest *request = [[SBGetWorkDaysTimesRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    request.startDate = startDate;
    request.endDate = endDate;
    return request;
}

- (SBRequest *)getBookingDetails:(NSString *)bookingID callback:(SBRequestCallback)callback
{
    NSAssert(bookingID != nil, @"no booking ID");
    NSAssert(![bookingID isEqualToString:@""], @"no booking ID");
    SBGetBookingDetailsRequest *request = [[SBGetBookingDetailsRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    request.bookingID = bookingID;
    return request;
}

- (SBRequest *)cancelBookingWithID:(NSString *)bookingID callback:(SBRequestCallback)callback
{
    NSAssert(bookingID != nil, @"no booking ID");
    NSAssert(![bookingID isEqualToString:@""], @"no booking ID");
    SBCancelBookingRequest *request = [[SBCancelBookingRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.delegate = self;
    request.callback = callback;
    request.bookingID = bookingID;
    return request;
}

- (SBRequest *)getUnitList:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetUnitListRequest class] callback:callback];
}

- (SBRequest *)getEventList:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetEventListRequest class] callback:callback];
}

- (SBRequest *)getClientListWithPattern:(NSString *)pattern callback:(SBRequestCallback)callback
{
    SBGetClientListRequest *request = [[SBGetClientListRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.pattern = pattern ? pattern : @"";
    request.callback = callback;
    request.delegate = self;
    return request;
}

- (SBRequest *)getClientWithId:(NSString *)clientID callback:(SBRequestCallback)callback
{
    NSParameterAssert(clientID != nil && ![clientID isEqualToString:@""]);
    SBGetClientRequest *request = [[SBGetClientRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.clientID = clientID;
    request.callback = callback;
    request.delegate = self;
    return request;
}

- (SBRequest *)addClientWithName:(NSString *)name phone:(NSString *)phone email:(NSString *)email callback:(SBRequestCallback)callback
{
    NSParameterAssert(phone != nil && ![phone isEqualToString:@""]);
    NSParameterAssert(email != nil && ![email isEqualToString:@""]);
    SBAddClientRequest *request = [[SBAddClientRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.clientName = name;
    request.phone = phone;
    request.email = email;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getAdditionalFieldsForEvent:(NSString *)eventID callback:(SBRequestCallback)callback
{
    NSParameterAssert(eventID != nil);
    SBGetAdditionalFieldsRequest *request = [[SBGetAdditionalFieldsRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.eventID = eventID;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)book:(SBBookingForm *)formData callback:(SBRequestCallback)callback
{
    SBBookRequest *reqeust = [[SBBookRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    reqeust.formData = formData;
    reqeust.callback = callback;
    reqeust.delegate = self;
    return reqeust;
}

- (SBRequest *)editBooking:(SBBookingForm *)formData callback:(SBRequestCallback)callback
{
    SBEditBookRequest *reqeust = [[SBEditBookRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    reqeust.formData = formData;
    reqeust.callback = callback;
    reqeust.delegate = self;
    return reqeust;
}

- (SBRequest *)addDeviceToken:(NSString *)deviceToken callback:(SBRequestCallback)callback
{
    NSParameterAssert(deviceToken != nil);
    SBAddDeviceTokenRequest *request = [[SBAddDeviceTokenRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.deviceToken = deviceToken;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)deleteDeviceToken:(NSString *)deviceToken callback:(SBRequestCallback)callback
{
    NSParameterAssert(deviceToken != nil);
    SBDeleteDeviceToken *request = [[SBDeleteDeviceToken alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.deviceToken = deviceToken;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getCompanyParam:(NSString *)paramKey callback:(SBRequestCallback)callback
{
    NSParameterAssert(paramKey != nil);
    NSParameterAssert(![paramKey isEqualToString:@""]);
    SBGetCompanyParamRequest *request = [[SBGetCompanyParamRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.paramKey = paramKey;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getGoogleCalendarBusyTimeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate unitID:(NSString *)unitID callback:(SBRequestCallback)callback
{
    NSParameterAssert(fromDate != nil);
    NSParameterAssert(toDate != nil);
    NSParameterAssert(unitID != nil && ![unitID isEqualToString:@""]);
    SBGetGoogleCalendarBusyTimeRequest *request = [[SBGetGoogleCalendarBusyTimeRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.startDate = fromDate;
    request.endDate = toDate;
    request.unitID = unitID;
    request.callback = callback;
    return request;
}

- (SBRequest *)getLocationsWithCallback:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetLocationsListRequest class] callback:callback];
}

#pragma mark - Statuses plugin

- (SBRequest *)getStatusesList:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetStatusesRequest class] callback:callback];
}

- (SBRequest *)setStatus:(NSString *)statusID forBooking:(NSString *)bookingID callback:(SBRequestCallback)callback
{
    NSParameterAssert(statusID != nil);
    NSParameterAssert(![statusID isEqualToString:@""]);
    NSParameterAssert(bookingID != nil);
    NSParameterAssert(![bookingID isEqualToString:@""]);
    SBSetStatusRequest *request = [[SBSetStatusRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.bookingID = bookingID;
    request.statusID = statusID;
    request.delegate = self;
    request.callback = callback;
    return request;
}

#pragma mark -

- (SBRequest *)isPluginActivated:(NSString *)pluginName callback:(SBRequestCallback)callback
{
    NSParameterAssert(pluginName != nil);
    NSParameterAssert(![pluginName isEqualToString:@""]);
    SBIsPluginActivatedRequest *request = [[SBIsPluginActivatedRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.pluginName = pluginName;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getWorkloadForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate performerID:(NSString *)performerID callback:(SBRequestCallback)callback;
{
    SBGetWorkloadRequest *request = [[SBGetWorkloadRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.startDate = startDate;
    request.endDate = endDate;
    request.performerID = performerID;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getCurrentTariffInfo:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetCurrentTariffInfoRequest class] callback:callback];
}

- (SBRequest *)getTopPerformers:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetTopPerformersRequest class] callback:callback];
}

- (SBRequest *)getTopServices:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetTopServicesRequest class] callback:callback];
}

- (SBRequest *)getBookingCancellationsInfoForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate callback:(SBRequestCallback)callback
{
    SBGetBookingCancellationsInfoRequest *request = [[SBGetBookingCancellationsInfoRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.startDate = startDate;
    request.endDate = endDate;
    request.delegate = self;
    request.callback = callback;
    return request;
}

- (SBRequest *)getVisitorStats:(SBRequestCallback)callback
{
    return [self buildRequest:[SBGetVisitorStatsRequest class] callback:callback];
}

- (SBRequest *)getBookingsStatsForPeriod:(NSString *)timePeriod callback:(SBRequestCallback)callback
{
    if (!timePeriod) {
        timePeriod = kSBTimePeriodWeek;
    }
    SBGetBookingStatsRequest *request = [[SBGetBookingStatsRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
    request.timePeriod = timePeriod;
    request.delegate = self;
    request.callback = callback;
    return request;
}

@end

@implementation SBSession (ApproveBookingPluginSupport)


- (SBRequest *)getPendingBookingsWithCallback:(SBRequestCallback)callback
{
    return [self buildRequest:[SBPluginApproveGetPendingBookingsRequest class] callback:callback];
}

- (SBRequest *)getPendingBookingsCountWithCallback:(SBRequestCallback)callback
{
    return [self buildRequest:[SBPluginApproveGetPendingBookingsCountRequest class] callback:callback];
}

- (SBRequest *)setBookingApproved:(BOOL)approved bookingID:(NSString *)bookingID callback:(SBRequestCallback)callback
{
    NSParameterAssert(bookingID != nil);
    if (approved) {
        SBPluginApproveBookingApproveRequest *request = [[SBPluginApproveBookingApproveRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
        request.bookingID = bookingID;
        request.delegate = self;
        request.callback = callback;
        return request;
    }
    else {
        SBPluginApproveBookingCancelRequest *request = [[SBPluginApproveBookingCancelRequest alloc] initWithToken:self.token comanyLogin:self.companyLogin];
        request.bookingID = bookingID;
        request.delegate = self;
        request.callback = callback;
        return request;
    }
}

@end