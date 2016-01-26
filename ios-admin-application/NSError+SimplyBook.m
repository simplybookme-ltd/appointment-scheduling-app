//
//  NSError+SimplyBook.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 14.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "NSError+SimplyBook.h"
#import "SBRequestOperation.h"
#import "SBSessionManager.h"

@implementation NSError (SimplyBook)

- (NSString *)message
{
    if ([self.domain isEqualToString:SBRequestErrorDomain]) {
        switch (self.code) {
            case SBServerErrorCode:
                return [NSString stringWithFormat:NSLS(@"Server respond with error: %@.", @""), self.userInfo[SBServerMessageKey]];
                break;
            case SBEmptyResponseErrorCode:
                return NSLS(@"Server not responding. Please try again later or contact our team.", @"");
                break;
            case SBEmptyResponseBodyErrorCode:
                return NSLS(@"Server response with no data.", @"");
                break;
            case SBUnexpectedServerResponseErrorCode:
                return NSLS(@"Sorry, server temporary unavailable.", @"");
                break;
            case SBUnknownErrorCode:
                return NSLS(@"Unknown error occurred.", @"");
                break;
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorTimedOut:
                return NSLS(@"Connection lost. Please check your internet connection and try again.", @"");
            default:
                return NSLS(@"Unexpected error occurred. Please try again later.", @"");
                break;
        }
    } else if ([self.domain isEqualToString:SBSessionManagerErrorDomain]) {
        switch (self.code) {
            case SBNoTokenErrorCode:
                return NSLS(@"No authorization response from server. Please try again later or contact support team.", @"");
                break;
            case SBWrongCredentialsErrorCode:
                return NSLS(@"Wrong credentials. Please check your login and password.",@"");
            default:
                return NSLS(@"Unexpected error occurred. Please try again later.", @"");
                break;
        }
    } else if ([self.domain isEqualToString:NSURLErrorDomain]) {
        switch (self.code) {
            case NSURLErrorCancelled:
                return NSLS(@"Request to server canceled.",@"");
                break;
            case NSURLErrorTimedOut:
            case NSURLErrorNotConnectedToInternet:
                return NSLS(@"Cannot connect to server. Please check your internet connection and try again.",@"");
            default:
                return NSLS(@"Failed to connect to server. Please try again later.",@"");
                break;
        }
    } else if ([self.domain isEqualToString:SBServerErrorDomain]) {
        switch (self.code) {
            case SB_SERVER_ERROR_PLUGIN_DISABLED:
            case SB_SERVER_ERROR_EVENT_ID_VALUE:
            case SB_SERVER_ERROR_UNIT_ID_VALUE:
            case SB_SERVER_ERROR_DATE_VALUE:
            case SB_SERVER_ERROR_TIME_VALUE:
            case SB_SERVER_ERROR_RECURRENT_BOOKING:
            case SB_SERVER_ERROR_CLIENT_NAME_VALUE:
            case SB_SERVER_ERROR_CLIENT_EMAIL_VALUE:
            case SB_SERVER_ERROR_CLIENT_PHONE_VALUE:
            case SB_SERVER_ERROR_CLIENT_ID:
            case SB_SERVER_ERROR_ADDITIONAL_FIELDS:
            case SB_SERVER_ERROR_APPOINTMENT_NOT_FOUND:
            case SB_SERVER_ERROR_SIGN:
            case SB_SERVER_ERROR_APPLICATION_CONFIRMATION:
            case SB_SERVER_ERROR_BATCH_NOT_FOUND:
            case SB_SERVER_ERROR_UNSUPPORTED_PAYMENT_SYSTEM:
            case SB_SERVER_ERROR_PAYMENT_FAILED:
            case SB_SERVER_ERROR_REQUIRED_PARAMS_MISSED:
            case SB_SERVER_ERROR_PARAMS_IS_NOT_ARRAY:
            default:
                return [NSString stringWithFormat:NSLS(@"Server respond with error: %@.", @""), self.userInfo[SBServerMessageKey]];
        }
    } else {
        return [NSString stringWithFormat:@"%@. %@", self.domain, self.localizedDescription];
    }
}

@end
