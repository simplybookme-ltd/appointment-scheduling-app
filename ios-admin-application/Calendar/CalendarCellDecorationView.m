//
//  CalendarCellDecorationView.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarCellDecorationView.h"
#import "CalendarLayoutAttributes.h"

static NSString * kCalendarCellDecorationViewKind = @"kCalendarCellDecorationViewKind";
NSString *_Nonnull const kHorizontalLineDecorationViewKind = @"kHorizontalLineDecorationViewKind";

@implementation CalendarCellDecorationView

+ (NSString *)kind
{
    return kCalendarCellDecorationViewKind;
}

+ (UIColor *)gridColor
{
    return [UIColor colorWithRed:0.783922 green:0.780392 blue:0.8 alpha:1];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [[self class] gridColor];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[self class] gridColor];
    }
    return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if ([layoutAttributes isKindOfClass:[CalendarLayoutAttributes class]]) {
        CalendarLayoutAttributes *attributes = (CalendarLayoutAttributes *)layoutAttributes;
        self.backgroundColor = [attributes backgroundColor];
        self.layer.cornerRadius = attributes.cornerRadius;
    }
}

@end
