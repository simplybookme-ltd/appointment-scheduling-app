//
//  CalendarBookingPresenter.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBBooking.h"
#import "SBPerformer.h"

NS_ASSUME_NONNULL_BEGIN

@class SBBookingStatusesCollection;
@class SBCollection;

@protocol CalendarBookingPresenter <NSObject>

- (nullable UIColor *)backgroundColorForBooking:(NSObject<SBBookingProtocol> *)booking;

@end

/// represents default booking presentetion parameters
@interface CalendarBookingDefaultPresenter : NSObject<CalendarBookingPresenter>

+ (instancetype)presenter;

@end

/// represents booking presentation parameters depending on booking status
/// @see Status plugin http://wiki.simplybook.me/index.php/Plugins#Status
@interface CalendarBookingStatusPresenter : NSObject<CalendarBookingPresenter>

- (instancetype)initWithStatuses:(SBBookingStatusesCollection *)statuses;

@end

/// represents booking presentation parameters depending on booking's performer properties
/// @see http://wiki.simplybook.me/index.php/Plugins#Provider.27s_color_coding_plugin
@interface CalendarBookingPerformerPresenter : NSObject<CalendarBookingPresenter>

- (instancetype)initWithPerformers:(SBPerformersCollection *)performers;

@end

NS_ASSUME_NONNULL_END
