//
//  SBUser.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 07.06.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBUser.h"
#import "NSDateFormatter+ServerParser.h"

NSString * const kSBACLRoleSeniorEmployee = @"shop_user";
NSString * const kSBACLRoleJuniorEmployee = @"station_user";
NSString * const kSBACLRoleAdministrator = @"admin";
NSString * const kSBACLRoleViewer = @"viewer";
NSString * const kSBACLRoleResellerAdmin = @"reseller_company_admin";


NSDictionary<NSNumber *, NSNumber *> *ACLRulesRolesMap(NSString *ACLRole) {
    static dispatch_once_t onceToken;
    static NSDictionary *ACLRulesRolesMap = nil;
    dispatch_once(&onceToken, ^{
        ACLRulesRolesMap = @{
                             kSBACLRoleAdministrator: @{
                                     @(SBACLRuleCreateBooking): @YES,
                                     @(SBACLRuleEditBooking): @YES,
                                     @(SBACLRuleEditOwnBooking): @YES,
                                     @(SBACLRuleEditBookingStatus): @YES,
                                     @(SBACLRulePerformersFullListAccess): @YES,
                                     @(SBACLRuleServicesFullListAccess): @YES,
                                     @(SBACLRuleDashboardAccess): @YES,
                                     },
                             kSBACLRoleResellerAdmin: @{
                                     @(SBACLRuleCreateBooking): @YES,
                                     @(SBACLRuleEditBooking): @YES,
                                     @(SBACLRuleEditOwnBooking): @YES,
                                     @(SBACLRuleEditBookingStatus): @YES,
                                     @(SBACLRulePerformersFullListAccess): @YES,
                                     @(SBACLRuleServicesFullListAccess): @YES,
                                     @(SBACLRuleDashboardAccess): @YES,
                                     },
                             kSBACLRoleSeniorEmployee: @{
                                     @(SBACLRuleCreateBooking): @YES,
                                     @(SBACLRuleEditBooking): @YES,
                                     @(SBACLRuleEditOwnBooking): @YES,
                                     @(SBACLRuleEditBookingStatus): @YES,
                                     @(SBACLRulePerformersFullListAccess): @YES,
                                     @(SBACLRuleServicesFullListAccess): @YES,
                                     @(SBACLRuleDashboardAccess): @NO,
                                     },
                             kSBACLRoleJuniorEmployee: @{
                                     @(SBACLRuleCreateBooking): @YES,
                                     @(SBACLRuleEditBooking): @NO,
                                     @(SBACLRuleEditOwnBooking): @YES,
                                     @(SBACLRuleEditBookingStatus): @YES,
                                     @(SBACLRulePerformersFullListAccess): @NO,
                                     @(SBACLRuleServicesFullListAccess): @NO,
                                     @(SBACLRuleDashboardAccess): @NO,
                                     },
                             kSBACLRoleViewer: @{
                                     @(SBACLRuleCreateBooking): @NO,
                                     @(SBACLRuleEditBooking): @NO,
                                     @(SBACLRuleEditOwnBooking): @NO,
                                     @(SBACLRuleEditBookingStatus): @YES,
                                     @(SBACLRulePerformersFullListAccess): @YES,
                                     @(SBACLRuleServicesFullListAccess): @YES,
                                     @(SBACLRuleDashboardAccess): @NO,
                                     },
                             };
    });
    return ACLRulesRolesMap[ACLRole];
}

@interface SBUser()

@property (nonatomic, strong, readwrite) NSString *userID;
@property (nonatomic, strong, readwrite) NSString *login;
@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *firstName;
@property (nonatomic, strong, readwrite) NSString *lastName;
@property (nonatomic, strong, readwrite) NSString *phone;
@property (nonatomic, strong, readwrite) NSString *ACLRole;
@property (nonatomic, readwrite, getter=isBlocked) BOOL blocked;
@property (nonatomic, strong, readwrite) NSDate *lastAccessDate;
@property (nonatomic, strong, readwrite) NSString *associatedPerformerID;

@end

@implementation SBUser

- (instancetype)initWithDict:(NSDictionary *)dict
{
    NSParameterAssert(dict != nil);
    NSParameterAssert(dict[@"id"] != nil && ![dict[@"id"] isEqualToString:@""]);
    NSParameterAssert(dict[@"login"] != nil && ![dict[@"login"] isEqualToString:@""]);
    self = [super init];
    if (self) {
        self.userID = dict[@"id"];
        self.login = dict[@"login"];
        self.email = dict[@"email"];
        self.firstName = dict[@"firstname"];
        self.lastName = dict[@"lastname"];
        self.phone = dict[@"phone"];
        self.ACLRole = dict[@"group"];
        self.blocked = [[NSNumber numberWithInteger:[dict[@"is_blocked"] integerValue]] boolValue];
        self.lastAccessDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:SAFE_KEY(dict, @"last_access_time")];
        self.associatedPerformerID = SAFE_KEY(dict, @"unit_group_id");
    }
    return self;
}

- (BOOL)hasAccessToACLRule:(SBACLRule)rule
{
    NSNumber *value = ACLRulesRolesMap(self.ACLRole)[@(rule)];
    return value != nil ? value.boolValue : NO;
}

@end
