//
//  SBBookingInfo.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBookingInfo.h"
#import "SBAdditionalField.h"
#import "NSDateFormatter+ServerParser.h"
#import "UIColor+SimplyBookColors.h"
#import "SBPluginsRepository.h"

@interface SBBookingPromo ()

@property (nonatomic, strong, readwrite) NSString *promoID;
@property (nonatomic, readwrite) CGFloat discount;
@property (nonatomic, strong, readwrite) NSString *code;
@property (nonatomic, strong, readwrite) NSString *pluginPromoID;
@property (nonatomic, strong, readwrite) NSString *schedulerID;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

@implementation SBBookingInfo

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.bookingID = dict[@"id"];
        self.clientID = SAFE_KEY(dict, @"client_id");
        self.isConfirmed = SAFE_KEY(dict, @"is_confirmed");
        self.eventID = SAFE_KEY(dict, @"event_id");
        self.eventName = SAFE_KEY(dict, @"event_name");
        self.unitID = SAFE_KEY(dict, @"unit_id");
        self.unitName = SAFE_KEY(dict, @"unit_name");
        self.code = SAFE_KEY(dict, @"code");
        self.createdDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:dict[@"record_date"]];
        self.startDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:dict[@"start_date_time"]];
        self.endDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:dict[@"end_date_time"]];
        self.approveStatus = SAFE_KEY(dict, @"approve_status");
        
        self.company = [[SBBookingInfoCompany alloc] initWithDict:dict];
        self.location = [[SBBookingInfoLocation alloc] initWithDict:dict[@"location"]];
        if (SAFE_KEY(dict, @"status") != nil) {
            self.status = [[SBBookingStatus alloc] initWithDict:dict[@"status"]];
        }
        else {
            self.status = nil;
        }
        self.price = [[SBBookingInfoPrice alloc] initWithDict:SAFE_KEY(dict, @"price")];
        self.promo = [[SBBookingPromo alloc] initWithDict:SAFE_KEY(dict, @"promo")];
        
        NSMutableArray *fields = [NSMutableArray array];
        for (NSDictionary *fieldDict in SAFE_KEY(dict, @"additional_fields")) {
            SBBookingInfoAdditionalField *additionalField = [[SBBookingInfoAdditionalField alloc] initWithDict:fieldDict];
            [fields addObject:additionalField];
        }
        self.additionalFields = [fields sortedArrayWithOptions:0 usingComparator:^(SBBookingInfoAdditionalField *field1, SBBookingInfoAdditionalField *field2) {
            return [field1.position compare:field2.position];
        }];

        /// if some fields contains value then we can say that some plugins enabled
        
        /// server always returns status object. even if plugin not enabled. it returns
        /// default status object if booking don't have any. so if this field is empty
        /// then statuses plugin not enabled
        [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryStatusPlugin enabled:(self.status != nil)];

        /// server always return location object. event if plugin not enabled. it returns
        /// default location object if booking don't have any. so if this field is empty
        /// then locations plugin not enabled.
        [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryLocationsPlugin enabled:(self.location != nil)];
        
        if (dict[@"approve_status"]) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryApproveBookingPlugin enabled:YES];
        }
        if (self.price) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryPaidEventsPlugin enabled:YES];
        }
        if (self.promo) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositorySimplySmartPromotionsPlugin enabled:YES];
        }
        if (self.additionalFields.count > 0) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryAdditionalFieldsPlugin enabled:YES];
        }
    }
    return self;
}

@end

@implementation SBBookingInfoCompany

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.email = dict[@"company_email"];
        self.login = dict[@"company_login"];
        self.name = dict[@"company_name"];
        self.phone = SAFE_KEY(dict, @"company_phone");
    }
    return self;
}

@end

@implementation SBBookingInfoLocation

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if ([dict isKindOfClass:[NSArray class]] || !dict) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.locationID = dict[@"id"];
        self.addressOne = SAFE_KEY(dict, @"address1");
        self.addressTwo = SAFE_KEY(dict, @"address2");
        self.city = SAFE_KEY(dict, @"city");
        self.picture = SAFE_KEY(dict, @"picture");
        self.phone = SAFE_KEY(dict, @"phone");
        self.locationDescription = SAFE_KEY(dict, @"description");
        self.longitude = SAFE_KEY(dict, @"lng");
        self.latitude = SAFE_KEY(dict, @"lat");
        self.title = SAFE_KEY(dict, @"title");
        self.isDefault = SAFE_KEY(dict, @"is_default");
        self.position = SAFE_KEY(dict, @"position");
    }
    return self;
}

- (NSString *)address
{
    NSMutableString *str = [NSMutableString string];
    NSString *appendFormat = @"%@";
    if (self.city) {
        [str appendString:self.city];
        appendFormat = @" %@";
    }
    if (self.addressOne) {
        [str appendFormat:appendFormat, self.addressOne];
        appendFormat = @" %@";
    }
    if (self.addressTwo) {
        [str appendFormat:appendFormat, self.addressTwo];
    }
    return str;
}

@end

@implementation SBBookingInfoPrice

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if ([dict isKindOfClass:[NSArray class]] || !dict) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.priceID = dict[@"id"];
        self.schedulerID = dict[@"sheduler_id"];
        self.amount = @([SAFE_KEY(dict, @"amount") floatValue]);
        self.currency = SAFE_KEY(dict, @"currency");
        self.status = SAFE_KEY(dict, @"status");
        self.paymentProcessor = SAFE_KEY(dict, @"payment_processor");
        self.paymentProcessorID = SAFE_KEY(dict, @"payment_processor_id");
        self.operationDate = dict[@"operation_datetime"] ? [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:dict[@"operation_datetime"]] : nil;
    }
    return self;
}

@end

@interface SBBookingInfoAdditionalField ()

@property (nonatomic, readwrite) BOOL isNull;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSNumber *type;
@property (nonatomic, readwrite) NSNumber *position;
@property (nonatomic, readwrite) id defaultValue;

@end

@implementation SBBookingInfoAdditionalField

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if ([dict isKindOfClass:[NSArray class]] || !dict) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.isNull = NO;
        self.name = dict[@"field_name"];
        self.title = dict[@"field_title"];
        self.type = @([SBAdditionalField typeFromString:dict[@"field_type"]]);
        self.value = dict[@"value"];
        self.position = dict[@"field_position"];
        self.defaultValue = nil;
    }
    return self;
}

- (BOOL)isValid
{
    return YES;
}

@end

@implementation SBBookingPromo

- (instancetype)initWithDict:(__kindof NSDictionary *)dict
{
    if (![dict isKindOfClass:[NSDictionary class]] || !dict) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.code = dict[@"code"];
        self.promoID = dict[@"id"];
        self.discount = [dict[@"discount"] floatValue] / 100.;
        self.pluginPromoID = dict[@"plugin_promo_id"];
        self.schedulerID = dict[@"sheduler_id"];
    }
    return self;
}

@end