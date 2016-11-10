//
// LSWeekView.h
//
// The MIT License (MIT)
//
// Created by Christoph Zelazowski on 8/25/13.
// Copyright (c) 2012-2014 Lumen Spark LLC ( http://lumenspark.com )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger, LSWeekViewStyle) {
    LSWeekViewStyleDefault              = 0,        // Weekday labels appear at the top, selected date label appears at the bottom
    LSWeekViewStyleReversedDayLabels    = 1 << 0,   // Selected date label appears at the top, weekday labels appear at the bottom
    LSWeekViewStyleWeekDayLabelsHidden  = 1 << 1,   // Weekday labels are hidden
    LSWeekViewStyleSquareDateMarkers    = 1 << 2,   // Selected date markers appear as squares rather than circlers
};

typedef void (^DidChangeSelectedDateBlock)(NSDate *selectedDate);

/**
 A scrollable week view, similar to the built-in week view in the iOS Calendar app (in Day view).
 */
@interface LSWeekView : UIView

/**
 By default is set to [NSCalendar firstWeekday]
 1 for sunday
 2 for monday
 3 for tuesday
 ...
 */
@property (nonatomic) NSUInteger firstWeekday;

#pragma mark - Lifecycle
/** @name Lifecycle */

/**
 Initializes the receiver.

 @param frame rectangle for the view
 @param style to be used
 */
- (instancetype)initWithFrame:(CGRect)frame style:(LSWeekViewStyle)style;

#pragma mark - Updating display settings
/** @name Updating display settings */

/**
 The calendar used for date calculations. Default is set to `[NSCalendar currentCalendar]`.
 */
@property (nonatomic, strong) NSCalendar *calendar;

/**
 Updates the view using current locale and time zone settings.
 */
- (void)reloadData;


#pragma mark - Updating font and color settings
/** @name Updating font and color settings */

/**
 If true, the selected date label will use the default tint color to accentuate today's date.
 */
@property (nonatomic, assign) BOOL accentuateSelectedDateLabel;

/**
 The color used for week day labels.
 */
@property (nonatomic, retain) UIColor *darkTextColor;

/**
 The color used for Sat and Sun day labels.
 */
@property (nonatomic, retain) UIColor *grayTextColor;

/**
 The font used for day labels.
 */
@property (nonatomic, strong) UIFont *dayLabelFont;

/**
 The font used for the selected date label.
 */
@property (nonatomic, strong) UIFont *selectedDateLabelFont;

/**
 The font used for weekday labels.
 */
@property (nonatomic, strong) UIFont *weekdayLabelFont;


#pragma mark - Date selections
/** @name Date selections */

/**
 Animates the selected date marker to accentuate date selection.
 */
- (void)animateSelectedDateMarker;

/**
 The block to be executed when date selection changes in response to user interaction.
 */
@property (nonatomic, copy) DidChangeSelectedDateBlock didChangeSelectedDateBlock;

/**
 The currently selected date.
 */
@property (nonatomic, strong) NSDate *selectedDate;

/**
 Sets the selected date, optionally animating the transition.
 
 @param selectedDate to be set
 @param animated set to true if the transition should be animated
 @return false if the `newDate` corresponds to the same day that's already been set
 */
- (BOOL)setSelectedDate:(NSDate *)selectedDate animated:(BOOL)animated;

+ (CGFloat)preferredHeightForTraitCollection:(UITraitCollection *)traitCollection;

@end
