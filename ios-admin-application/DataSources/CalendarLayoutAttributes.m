//
//  CalendarLayoutAttributes.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarLayoutAttributes.h"

@interface CalendarLayoutAttributes ()

@property (nonatomic) BOOL xAdjusted;
@property (nonatomic) CGFloat startOffset;
@property (nonatomic) CGFloat duration;

@end

@implementation CalendarLayoutAttributes

- (id)copyWithZone:(NSZone *)zone
{
    typeof (self) copy = [super copyWithZone:zone];
    copy.backgroundColor = [self.backgroundColor copyWithZone:zone];
    copy.stickyX = self.stickyX;
    copy.stickyY = self.stickyY;
    copy.cornerRadius = self.cornerRadius;
    copy.headlineHeight = self.headlineHeight;
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {%@, X-%d, Y-%d, Offset: %f, Duration: %f}", [super description], self.backgroundColor.description, self.stickyX, self.stickyY, self.startOffset, self.duration];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        if (self.stickyX != [other stickyX] || self.stickyY != [other stickyY]) {
            return NO;
        }
        if (self.backgroundColor == nil && [other backgroundColor] == nil) {
            return YES;
        }
        return [self.backgroundColor isEqual:[other backgroundColor]];
    }
}

@end

@implementation CalendarLayoutAttributes (CalendarGridCollectionViewLayout)
@end
