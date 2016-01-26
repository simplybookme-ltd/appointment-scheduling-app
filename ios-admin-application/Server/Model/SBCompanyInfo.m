//
//  SBCompanyInfo.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 06.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBCompanyInfo.h"
#import "NSString+HTML.h"

NSString * const kSBCompanyClientRequiredFieldsParamKey = @"require_fields";
NSString * const kSBCompanyClientRequiredFieldsValuePhone = @"phone";
NSString * const kSBCompanyClientRequiredFieldsValueEmail = @"email";
NSString * const kSBCompanyClientRequiredFieldsValueEmailAndPhone = @"email_phone";
          
@implementation SBCompanyInfo

@synthesize serverTimeZone = _serverTimeZone;
@synthesize timeZone = _timeZone;

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.address = SAFE_KEY(dict, @"address");
        self.addressOne = SAFE_KEY(dict, @"address1");
        self.addressTwo = SAFE_KEY(dict, @"address2");
        self.city = SAFE_KEY(dict, @"city");
        self.companyName = SAFE_KEY(dict, @"name");
        self.email = SAFE_KEY(dict, @"email");
        self.login = SAFE_KEY(dict, @"login");
        self.logoPath = SAFE_KEY(dict, @"logo");
        self.phone = SAFE_KEY(dict, @"phone");
        self.companyDescription = SAFE_KEY(dict, @"description_text");
        if (self.companyDescription) {
            self.companyDescription = [[self.companyDescription stringByDecodingHTMLEntities] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        self.longitude = SAFE_KEY(dict, @"lng");
        self.latitude = SAFE_KEY(dict, @"lat");
        self.timeframe = SAFE_KEY(dict, @"timeframe");
        self.timezoneName = SAFE_KEY(dict, @"timezone");
        self.showInClientTimeZone = [SAFE_KEY(dict, @"show_in_client_timezone") boolValue];
    }
    return self;
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.latitude = @(newCoordinate.latitude);
    self.longitude = @(newCoordinate.longitude);
}

- (NSString *)title
{
    return self.companyName;
}

- (NSString *)subtitle
{
    return self.companyDescription;
}

+ (NSString *)localizedStringForServiceDuration:(NSInteger)duration
{
    if (duration % 60 == 0) {
        return [NSString stringWithFormat:@"%ld%@", (long)(duration/60), NSLS(@"h",@"")];
    } else if (duration > 60) {
        return [NSString stringWithFormat:@"%ld%@ %ld%@", (long)(duration/60), NSLS(@"h", @""), (long)(duration%60), NSLS(@"min",@"")];
    } else {
        return [NSString stringWithFormat:@"%ld%@", (long)duration, NSLS(@"min",@"")];
    }
    return @"";
}

- (NSTimeZone *)serverTimeZone
{
    if (_serverTimeZone) {
        return _serverTimeZone;
    }
    if (self.showInClientTimeZone) {
        return [self timeZone];
    }
    _serverTimeZone = [NSTimeZone timeZoneWithName:self.timezoneName];
    return _serverTimeZone;
}

- (NSTimeZone *)timeZone
{
    if (_timeZone) {
        return _timeZone;
    }
    _timeZone = [NSTimeZone defaultTimeZone];
    return _timeZone;
}

@end
