//
//  DashboardWidgetUpdateStrategy.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardWidgetUpdateStrategy.h"
#import "DashboardAbstractWidgetDataSource.h"
#import "DashboardAbstractWidgetDataSource_Private.h"

@interface DashboardWidgetUpdateStrategy ()

@property (nonatomic, weak, nullable) DashboardAbstractWidgetDataSource *widget;

@end

@interface DashboardWidgetTimerUpdateStrategy : DashboardWidgetUpdateStrategy

@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic) NSTimeInterval timeInterval;

- (instancetype _Nullable)initWithTimerInterval:(NSTimeInterval)timeInterval
                                         widget:(DashboardAbstractWidgetDataSource *_Nonnull)widget;

@end

@interface DashboardWidgetNotificationUpdateStrategy : DashboardWidgetUpdateStrategy

@property (nonatomic, strong, nonnull) NSString *notificationName;
@property (nonatomic, strong, nullable) id observingObject;

- (instancetype _Nullable)initWithNotificationName:(NSString *_Nonnull)notificationName
                                   observingObject:(id _Nullable)observingObject
                                            widget:(DashboardAbstractWidgetDataSource *_Nonnull)widget;

@end

@implementation DashboardWidgetUpdateStrategy

+ (instancetype)timerUpdateStrategyWithTimeInterval:(NSTimeInterval)timeInterval
                                          forWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget
{
    return [[DashboardWidgetTimerUpdateStrategy alloc] initWithTimerInterval:timeInterval widget:widget];
}

+ (instancetype)notificationUpdateStrategyWithNotificationName:(NSString *_Nonnull)notificationName
                                               observingObject:(id _Nullable)observingObject
                                                     forWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget
{
    return [[DashboardWidgetNotificationUpdateStrategy alloc] initWithNotificationName:notificationName
                                                                       observingObject:observingObject
                                                                                widget:widget];
}

- (void)widgetDidFinishDataLoading
{
    NSAssertNotImplemented();
}

- (void)cancelUpdates
{
    NSAssertNotImplemented();
}

@end

#pragma mark -

@implementation DashboardWidgetTimerUpdateStrategy

- (instancetype _Nullable)initWithTimerInterval:(NSTimeInterval)timeInterval
                                         widget:(DashboardAbstractWidgetDataSource *_Nonnull)widget
{
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(widget != nil);
    self = [super init];
    if (self) {
        self.timeInterval = timeInterval;
        self.widget = widget;
    }
    return self;
}

- (void)dealloc
{
    [self cancelUpdates];
}

- (void)widgetDidFinishDataLoading
{
    if (!self.timer) {
        self.timer = [NSTimer timerWithTimeInterval:self.timeInterval
                                             target:self selector:@selector(timerHandler:)
                                           userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)cancelUpdates
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerHandler:(NSTimer *_Nonnull)timer
{
    [self.widget reloadData];
}

@end

#pragma mark -

@implementation DashboardWidgetNotificationUpdateStrategy

- (instancetype _Nullable)initWithNotificationName:(NSString *_Nonnull)notificationName
                                   observingObject:(id _Nullable)observingObject
                                            widget:(DashboardAbstractWidgetDataSource *_Nonnull)widget
{
    NSParameterAssert(notificationName != nil);
    NSParameterAssert(widget != nil);
    self = [super init];
    if (self) {
        self.notificationName = notificationName;
        self.observingObject = observingObject;
        self.widget = widget;
    }
    return self;
}

- (void)dealloc
{
    [self cancelUpdates];
}

- (void)cancelUpdates
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:self.notificationName object:self.observingObject];
}

- (void)widgetDidFinishDataLoading
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:)
                                                 name:self.notificationName object:self.observingObject];
}

- (void)notificationHandler:(NSNotification *_Nonnull)notification
{
    [self.widget reloadData];
}

@end
