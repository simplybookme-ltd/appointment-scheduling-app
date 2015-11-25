//
//  SBBookingStatusesCollection.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 13.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBookingStatusesCollection.h"
#import "UIColor+SimplyBookColors.h"

@interface SBBookingStatus ()

@property (nonatomic, strong, readwrite) NSString *statusID;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *HEXColor;
@property (nonatomic, readwrite) BOOL isDefault;

- (instancetype)initWithDict:(NSDictionary <NSString *, NSString *> *)dict;

@end

@interface SBBookingStatusesCollection ()

@property (nonatomic, strong) NSArray <SBBookingStatus *> *statuses;
@property (nonatomic, strong, readwrite) SBBookingStatus *defaultStatus;

@end

@implementation SBBookingStatusesCollection

- (instancetype)initWithStatusesList:(NSArray <NSDictionary <NSString *, NSString *> *> *)list
{
    NSParameterAssert(list != nil);
    self = [super init];
    if (self) {
        NSMutableArray *statuses = [NSMutableArray array];
        [list enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            SBBookingStatus *status = [[SBBookingStatus alloc] initWithDict:obj];
            [statuses addObject:status];
            if ([status isDefault]) {
                self.defaultStatus = status;
            }
        }];
        self.statuses = statuses;
    }
    return self;
}

- (NSUInteger)count
{
    return self.statuses.count;
}

- (NSAttributedString *)attributedTitleForStatus:(SBBookingStatus *)status
{
    NSString *string = [NSString stringWithFormat:@"• %@", status.name];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedString addAttributes:@{NSForegroundColorAttributeName: [UIColor colorFromHEXString:status.HEXColor]}
                              range:NSMakeRange(0, @"•".length)];
    return attributedString;
}

- (NSUInteger)indexForObject:(SBBookingStatus *)object
{
    NSParameterAssert(object != nil);
    return [self.statuses indexOfObject:object];
}

#pragma mark - Picker View Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.statuses.count;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    static NSMutableParagraphStyle *statuses_paragraphStyle = nil;
    if (!statuses_paragraphStyle) {
        statuses_paragraphStyle = [NSMutableParagraphStyle new];
        statuses_paragraphStyle.alignment = NSTextAlignmentLeft;
    }
    SBBookingStatus *status = self.statuses[row];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitleForStatus:status]];
    [attributedString addAttributes:@{NSParagraphStyleAttributeName: statuses_paragraphStyle}
                              range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

#pragma mark - Object Subscripting

- (SBBookingStatus *)objectAtIndexedSubscript:(NSUInteger)idx
{
    NSParameterAssert(idx < self.statuses.count);
    return self.statuses[idx];
}

- (nullable SBBookingStatus *)objectForKeyedSubscript:(NSString *)statusID
{
    NSParameterAssert(statusID != nil);
    for (SBBookingStatus *status in self.statuses) {
        if ([status.statusID isEqualToString:statusID]) {
            return status;
        }
    }
    return nil;
}

#pragma mark - Fast enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    return [self.statuses countByEnumeratingWithState:state objects:buffer count:len];
}

@end

#pragma mark -

@implementation SBBookingStatus

- (instancetype)initWithDict:(NSDictionary <NSString *, NSString *> *)dict
{
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSAssert(SAFE_KEY(dict,@"id") != nil, @"no required field 'id' found in status data dictionary");
    NSAssert(SAFE_KEY(dict,@"name") != nil, @"no required field 'name' found in status data dictionary");
    NSAssert(SAFE_KEY(dict,@"color") != nil, @"no required field 'color' found in status data dictionary");
    NSAssert(dict[@"is_default"] != nil, @"no required field 'is_default' found in status data dictionary");
    self = [super init];
    if (self) {
        self.statusID = dict[@"id"];
        self.name = dict[@"name"];
        self.HEXColor = dict[@"color"];
        self.isDefault = ([dict[@"is_default"] isEqual:[NSNull null]]) ? NO : [dict[@"is_default"] boolValue];
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        return [self.statusID isEqualToString:[other statusID]];
    }
}

- (NSUInteger)hash
{
    return self.statusID.hash;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"%@, %@%@, #%@", self.statusID, self.name, (self.isDefault ? @" (default)" : @""), self.HEXColor];
    [description appendString:@">"];
    return description;
}

@end
