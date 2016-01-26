//
//  CompanyInfo.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 06.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const kSBCompanyClientRequiredFieldsParamKey;
extern NSString * const kSBCompanyClientRequiredFieldsValuePhone;
extern NSString * const kSBCompanyClientRequiredFieldsValueEmail;
extern NSString * const kSBCompanyClientRequiredFieldsValueEmailAndPhone;
                 
@interface SBCompanyInfo : NSObject

@property (nonatomic, strong) NSString * address;
@property (nonatomic, strong) NSString * addressOne;
@property (nonatomic, strong) NSString * addressTwo;
@property (nonatomic, strong) NSString * city;
@property (nonatomic, strong) NSString * companyName;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * login;
@property (nonatomic, strong) NSString * logoPath;
@property (nonatomic, strong) NSString * phone;
@property (nonatomic, strong) NSString * companyDescription;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * timeframe;
@property (nonatomic) BOOL showInClientTimeZone;
@property (nonatomic, strong) NSString * timezoneName;
@property (nonatomic, readonly) NSTimeZone * serverTimeZone;
@property (nonatomic, readonly) NSTimeZone * timeZone;

@property (nonatomic, copy) NSNumber * isEventCategoryPluginActive;

@property(nonatomic, readonly, copy) NSString *title;
@property(nonatomic, readonly, copy) NSString *subtitle;

- (instancetype)initWithDict:(NSDictionary *)dict;

+ (NSString *)localizedStringForServiceDuration:(NSInteger)duration;

@end
