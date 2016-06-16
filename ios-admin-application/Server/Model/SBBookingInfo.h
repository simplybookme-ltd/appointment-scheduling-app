//
//  SBBookingInfo.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBAdditionalField.h"
#import "SBBookingStatusesCollection.h"

NS_ASSUME_NONNULL_BEGIN

@class SBBookingInfoAdditionalField;
@class SBBookingInfoCompany;
@class SBBookingInfoLocation;
@class SBBookingInfoPrice;
@class SBBookingPromo;

@interface SBBookingInfo : NSObject

@property (nonatomic, copy) NSString *bookingID;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSNumber *isConfirmed;
@property (nonatomic, copy) NSString *eventID;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSString *unitID;
@property (nonatomic, copy) NSString *unitName;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSDate *createdDate;
@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy, nullable) NSString *approveStatus;
@property (nonatomic, strong) NSArray<SBBookingInfoAdditionalField *> *additionalFields;
@property (nonatomic, strong) SBBookingInfoCompany *company;
@property (nonatomic, strong, nullable) SBBookingInfoLocation *location;
@property (nonatomic, strong, nullable) SBBookingStatus *status;
@property (nonatomic, strong, nullable) SBBookingInfoPrice *price;
@property (nonatomic, strong, nullable) SBBookingPromo *promo;

- (nullable instancetype)initWithDict:(NSDictionary *)dict;

@end

@interface SBBookingInfoCompany : NSObject

@property (nonatomic, copy) NSString * email;
@property (nonatomic, copy) NSString * login;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy, nullable) NSString * phone;

- (nullable instancetype)initWithDict:(NSDictionary *)dict;

@end

@interface SBBookingInfoLocation : NSObject

@property (nonatomic, copy) NSString * locationID;
@property (nonatomic, copy, nullable) NSString * addressOne;
@property (nonatomic, copy, nullable) NSString * addressTwo;
@property (nonatomic, copy, nullable) NSString * city;
@property (nonatomic, copy, nullable) NSString * picture;
@property (nonatomic, copy, nullable) NSString * phone;
@property (nonatomic, copy, nullable) NSString * locationDescription;
@property (nonatomic, copy, nullable) NSNumber * longitude;
@property (nonatomic, copy, nullable) NSNumber * latitude;
@property (nonatomic, copy, nullable) NSString * title;
@property (nonatomic, copy, nullable) NSNumber * isDefault;
@property (nonatomic, copy, nullable) NSNumber * position;

- (nullable instancetype)initWithDict:(nullable NSDictionary *)dict;
- (NSString *)address;

@end

@interface SBBookingInfoPrice : NSObject

@property (nonatomic, copy) NSNumber * priceID;
@property (nonatomic, copy) NSNumber * schedulerID;
@property (nonatomic, copy, nullable) NSNumber * amount;
@property (nonatomic, copy, nullable) NSString * currency;
@property (nonatomic, copy, nullable) NSString * status;
@property (nonatomic, copy, nullable) NSString * paymentProcessor;
@property (nonatomic, copy, nullable) NSString * paymentProcessorID;
@property (nonatomic, copy, nullable) NSDate * operationDate;

- (nullable instancetype)initWithDict:(nullable NSDictionary *)dict;

@end

@interface SBBookingInfoAdditionalField : NSObject <SBAdditionalFieldProtocol>

@property (nonatomic, readonly) BOOL isNull;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSNumber *type;
@property (nonatomic, readonly, nullable) id defaultValue;
@property (nonatomic, strong) id value;

- (nullable instancetype)initWithDict:(nullable NSDictionary *)dict;

@end

@interface SBBookingPromo : NSObject

@property (nonatomic, strong, readonly) NSString *promoID;
@property (nonatomic, readonly) CGFloat discount;
@property (nonatomic, strong, readonly) NSString *code;
@property (nonatomic, strong, readonly) NSString *pluginPromoID;
@property (nonatomic, strong, readonly) NSString *schedulerID;

@end

NS_ASSUME_NONNULL_END