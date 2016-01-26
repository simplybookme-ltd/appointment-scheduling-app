//
//  BookingDetailsViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface BookingDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, copy) NSString *bookingID;
@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, copy) NSString *clientEmail;
@property (nonatomic, copy) NSString *clientPhone;

@property (nonatomic, copy) void (^onBookingCanceledHandler)(NSString *bookingID);

@end
