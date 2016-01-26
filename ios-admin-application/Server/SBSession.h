//
//  SBSession.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSessionCredentials.h"
#import "SBResponse.h"
#import "SBRequest.h"
#import "SBGetBookingsFilter.h"
#import "SBBookingForm.h"
#import "SBSettings.h"

extern NSString * const kSBPendingBookings_DidUpdateNotification;
extern NSString * const kSBPendingBookings_BookingIDKey;
extern NSString * const kSBPendingBookings_BookingsCountKey;

extern NSString * const kSBTimePeriodWeek;

@interface SBSession : NSObject

@property (nonatomic, readonly, copy) NSString *companyLogin;
@property (nonatomic, readonly, copy) NSString *userLogin;
@property (nonatomic, readonly, strong) SBSettings *settings;

+ (instancetype)defaultSession;
+ (instancetype)restoreSessionWithCompanyLogin:(NSString *)companyLogin;

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin token:(NSString *)token;
- (void)invalidate;

- (void)assignSessionCredentials:(SBSessionCredentials *)credentials;

- (void)cancelRequestWithID:(NSString *)requestID;
- (void)cancelRequests:(NSArray *)requests;
- (void)repeatRequest:(SBRequest *)request;
- (void)performReqeust:(SBRequest *)request;

- (SBRequest *)getBookingsWithFilter:(SBGetBookingsFilter *)filter callback:(SBRequestCallback)callback;
- (SBRequest *)getCompanyInfoWithCallback:(SBRequestCallback)callback;
- (SBRequest *)getUnitWorkdayInfoForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate callback:(SBRequestCallback)callback;
- (SBRequest *)getWorkDaysTimesForDate:(NSDate *)startDate callback:(SBRequestCallback)callback;
- (SBRequest *)getWorkDaysTimesForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate callback:(SBRequestCallback)callback;
- (SBRequest *)getBookingDetails:(NSString *)bookingID callback:(SBRequestCallback)callback;
- (SBRequest *)cancelBookingWithID:(NSString *)bookingID callback:(SBRequestCallback)callback;
- (SBRequest *)getUnitList:(SBRequestCallback)callback;
- (SBRequest *)getEventList:(SBRequestCallback)callback;
- (SBRequest *)getClientListWithPattern:(NSString *)pattern callback:(SBRequestCallback)callback;
- (SBRequest *)addClientWithName:(NSString *)name phone:(NSString *)phone email:(NSString *)email callback:(SBRequestCallback)callback;
- (SBRequest *)getAdditionalFieldsForEvent:(NSString *)eventID callback:(SBRequestCallback)callback;
- (SBRequest *)book:(SBBookingForm *)formData callback:(SBRequestCallback)callback;
- (SBRequest *)editBooking:(SBBookingForm *)formData callback:(SBRequestCallback)callback;
- (SBRequest *)addDeviceToken:(NSString *)deviceToken callback:(SBRequestCallback)callback;
- (SBRequest *)deleteDeviceToken:(NSString *)deviceToken callback:(SBRequestCallback)callback;
- (SBRequest *)isPluginActivated:(NSString *)pluginName callback:(SBRequestCallback)callback;

// statuses plugin
- (SBRequest *)getStatusesList:(SBRequestCallback)callback;
- (SBRequest *)setStatus:(NSString *)statusID forBooking:(NSString *)bookingID callback:(SBRequestCallback)callback;

// dashboard requests
- (SBRequest *)getWorkloadForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate performerID:(NSString *)performerID callback:(SBRequestCallback)callback;
- (SBRequest *)getCurrentTariffInfo:(SBRequestCallback)callback;
- (SBRequest *)getTopPerformers:(SBRequestCallback)callback;
- (SBRequest *)getTopServices:(SBRequestCallback)callback;
- (SBRequest *)getBookingCancellationsInfoForStartDate:(NSDate *)date endDate:(NSDate *)endDate callback:(SBRequestCallback)callback;
- (SBRequest *)getVisitorStats:(SBRequestCallback)callback;
- (SBRequest *)getBookingsStatsForPeriod:(NSString *)timePeriod callback:(SBRequestCallback)callback;

@end

@interface SBSession (ApproveBookingPluginSupport)

- (SBRequest *)getPendingBookingsWithCallback:(SBRequestCallback)callback;
- (SBRequest *)getPendingBookingsCountWithCallback:(SBRequestCallback)callback;
- (SBRequest *)setBookingApproved:(BOOL)approved bookingID:(NSString *)bookingID callback:(SBRequestCallback)callback;

@end
