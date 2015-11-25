//
//  AddBookingViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBBookingForm.h"
#import "SBBookingStatusesCollection.h"

NS_ASSUME_NONNULL_BEGIN

@class SBBookingInfoAdditionalField;

@interface AddBookingViewController : UIViewController

@property (nonatomic, strong, nullable) SBBookingForm *bookingForm;
@property (nonatomic, copy, nullable) NSString *serviceName;
@property (nonatomic, copy, nullable) NSString *performerName;
@property (nonatomic, copy, nullable) NSDate *initialDate;
@property (nonatomic, copy, nullable) NSDate *preferedStartTime;
@property (nonatomic, copy, nullable) NSString *preferedPerformerID;
@property (nonatomic, strong, nullable) SBBookingStatus *bookingStatus;
@property (nonatomic, strong, nullable) NSArray <SBBookingInfoAdditionalField *> *additionalFieldsPreset;
@property (nonatomic) NSUInteger timeFrameStep;
@property (nonatomic, copy) void (^bookingCreatedHandler)(UIViewController *controller);
@property (nonatomic, copy) void (^bookingCanceledHandler)(UIViewController *controller);

@end

NS_ASSUME_NONNULL_END
