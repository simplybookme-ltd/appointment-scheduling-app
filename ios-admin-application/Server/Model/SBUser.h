//
//  SBUser.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 07.06.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSessionCredentials.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBACLRoleSeniorEmployee;
extern NSString * const kSBACLRoleJuniorEmployee;
extern NSString * const kSBACLRoleAdministrator;
extern NSString * const kSBACLRoleViewer;
extern NSString * const kSBACLRoleResellerAdmin;

typedef NS_ENUM(NSInteger, SBACLRule) {
    SBACLRuleCreateBooking,
    SBACLRuleEditBooking,
    SBACLRuleEditOwnBooking,
    SBACLRuleEditBookingStatus,
    SBACLRulePerformersFullListAccess,
    SBACLRuleServicesFullListAccess,
    SBACLRuleDashboardAccess,
    SBACLRulePendingBookingsAccess
};
                 
@interface SBUser : NSObject

@property (nonatomic, strong, nullable) SBSessionCredentials *credentials;
@property (nonatomic, strong, readonly) NSString *userID;
@property (nonatomic, strong, readonly) NSString *login;
@property (nonatomic, strong, readonly) NSString *email;
@property (nonatomic, strong, readonly) NSString *firstName;
@property (nonatomic, strong, readonly) NSString *lastName;
@property (nonatomic, strong, readonly) NSString *phone;
@property (nonatomic, strong, readonly) NSString *ACLRole;
@property (nonatomic, readonly, getter=isBlocked) BOOL blocked;
@property (nonatomic, strong, readonly, nullable) NSDate *lastAccessDate;
@property (nonatomic, strong, readonly, nullable) NSString *associatedPerformerID;

- (instancetype)initWithDict:(NSDictionary *)dict;

- (BOOL)hasAccessToACLRule:(SBACLRule)rule;

@end

NS_ASSUME_NONNULL_END
