//
//  SBBookingStatusesCollection.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 13.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Classes SBBookingStatus and SBBookingStatusesCollection are describe model for Status plugin.
 * @see SBGetStatusesRequest
 * @see http://wiki.simplybook.me/index.php/Plugins#Status
 */

@interface SBBookingStatus : NSObject

@property (nonatomic, strong, readonly) NSString *statusID;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *HEXColor;
@property (nonatomic, readonly) BOOL isDefault;

- (nullable instancetype)initWithDict:(nullable NSDictionary <NSString *, NSString *> *)dict;

@end

@interface SBBookingStatusesCollection : NSObject <NSFastEnumeration, UIPickerViewDataSource>

@property (nonatomic, strong, readonly) SBBookingStatus *defaultStatus;

- (instancetype)initWithStatusesList:(NSArray <NSDictionary <NSString *, NSString *> *> *)list;

- (NSArray <SBBookingStatus *> *)allObjects;
- (NSUInteger)indexForObject:(SBBookingStatus *)object;
- (SBBookingStatus *)objectAtIndexedSubscript:(NSUInteger)idx;
- (nullable SBBookingStatus *)objectForKeyedSubscript:(NSString *)statusID;
- (NSUInteger)count;
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (NSAttributedString *)attributedTitleForStatus:(SBBookingStatus *)status;

@end

NS_ASSUME_NONNULL_END
