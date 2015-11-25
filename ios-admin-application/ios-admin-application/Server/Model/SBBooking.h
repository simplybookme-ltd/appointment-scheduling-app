//
//  SBBooking.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SBBookingProtocol <NSObject>

@property (nonatomic, strong) NSString *bookingID;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *isConfirmed;
@property (nonatomic, strong) NSString *performerID;
@property (nonatomic, strong) NSString *statusID;

@end

typedef NSObject <SBBookingProtocol> SBBookingObject;

@interface SBBooking : NSObject <SBBookingProtocol>

@property (nonatomic, strong) NSString *bookingID;
@property (nonatomic, strong) NSString *clientName;
@property (nonatomic, strong) NSString *clientID;
@property (nonatomic, strong) NSString *clientPhone;
@property (nonatomic, strong) NSString *clientEmail;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSDate *recordDate;
@property (nonatomic, strong) NSString *performerName;
@property (nonatomic, strong) NSString *performerID;
@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, strong) NSNumber *isConfirmed;
@property (nonatomic, strong) NSString *statusID;
@property (nonatomic, strong) NSString *paymentStatus;
@property (nonatomic, strong) NSString *paymentSystem;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
