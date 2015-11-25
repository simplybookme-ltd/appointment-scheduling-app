//
//  SBDateRange.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 06.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBDateRange.h"

@implementation SBDateRange

+ (nullable instancetype)dateRangeWithStart:(NSDate *)start end:(NSDate *)end
{
    return [[self alloc] initWithStart:start end:end];
}

- (nullable instancetype)initWithStart:(NSDate *)start end:(NSDate *)end
{
    self = [super init];
    if (self) {
        self.start = start;
        self.end = end;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@ - %@>", NSStringFromClass([self class]), self.start, self.end];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[self class]]) {
        return NO;
    } else {
        return [self.start isEqual:[(SBDateRange *)other start]] && [self.end isEqual:[(SBDateRange *)other end]];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return NO;
}

- (BOOL)isEmpty
{
    return self.start == nil && self.end == nil;
}

- (BOOL)containsDate:(nonnull NSDate *)date
{
    NSParameterAssert(date != nil);
    if (!self.start) {
        return [date compare:self.end] <= NSOrderedSame;
    }
    if (!self.end) {
        return [date compare:self.start] >= NSOrderedSame;
    }
    return [date compare:self.start] >= NSOrderedSame && [date compare:self.end] <= NSOrderedSame;
}

@end
