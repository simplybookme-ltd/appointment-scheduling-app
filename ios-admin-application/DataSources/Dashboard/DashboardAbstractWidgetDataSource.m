//
//  DashboardAbstractWidgetDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardAbstractWidgetDataSource.h"
#import "DashboardAbstractWidgetDataSource_Private.h"
#import "SBSession.h"

NSString *_Nonnull const kDashboardLoadingIndicatorSupplementaryKind = @"kDashboardLoadingIndicatorSupplementaryKind";
NSString *_Nonnull const kDashboardLoadingIndicatorSupplementaryReuseIdentifier = @"kDashboardLoadingIndicatorSupplementaryReuseIdentifier";
NSString *_Nonnull const kDashboardErrorMessageSupplementaryKind = @"kDashboardErrorMessageSupplementaryKind";
NSString *_Nonnull const kDashboardErrorMessageSupplementaryReuseIdentifier = @"kDashboardErrorMessageSupplementaryReuseIdentifier";

@interface DashboardAbstractWidgetDataSource ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, SBRequestCallback> *callbacks;

@end

@implementation DashboardAbstractWidgetDataSource

- (instancetype _Nullable)init
{
    self = [super init];
    if (self) {
        self.callbacks = [NSMutableDictionary dictionary];
        self.preferredWidgetHeight = UITableViewAutomaticDimension;
    }
    return self;
}

- (void)dealloc
{
    if (self.dataUpdateStrategy) {
        [self.dataUpdateStrategy cancelUpdates];
    }
}

- (NSString *_Nonnull)reusableIdentifierForSupplementaryViewOnKind:(NSString *_Nonnull)kind
{
    NSParameterAssert([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind] || [kind isEqualToString:kDashboardErrorMessageSupplementaryKind]);
    if ([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind]) {
        return kDashboardLoadingIndicatorSupplementaryReuseIdentifier;
    }
    else if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        return kDashboardErrorMessageSupplementaryReuseIdentifier;
    }
    return @"";
}

- (NSString *_Nonnull)reusableIdentifierForItemAtIndexPath:(NSIndexPath *_Nonnull)indexPath
{
    return @"cell";
}

- (UINib *_Nonnull)nibForViewForSupplementaryElementOfKind:(NSString *_Nonnull)kind
{
    NSParameterAssert([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind] || [kind isEqualToString:kDashboardErrorMessageSupplementaryKind]);
    if ([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind]) {
        return [UINib nibWithNibName:@"ActivityIndicatorCollectionReusableView" bundle:nil];
    }
    if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        return [UINib nibWithNibName:@"MessageCollectionReusableView" bundle:nil];
    }
    return nil;
}

- (UINib *_Nonnull)nibForItemCellWithReuseIdentifier:(NSString *_Nonnull)reuseIdentifier
{
    NSAssertNotImplemented();
    return nil;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *_Nonnull)collectionView
{
    [collectionView registerNib:[self nibForViewForSupplementaryElementOfKind:kDashboardLoadingIndicatorSupplementaryKind]
     forSupplementaryViewOfKind:kDashboardLoadingIndicatorSupplementaryKind
            withReuseIdentifier:kDashboardLoadingIndicatorSupplementaryReuseIdentifier];
    [collectionView registerNib:[self nibForViewForSupplementaryElementOfKind:kDashboardErrorMessageSupplementaryKind]
     forSupplementaryViewOfKind:kDashboardErrorMessageSupplementaryKind
            withReuseIdentifier:kDashboardErrorMessageSupplementaryReuseIdentifier];
}

- (UICollectionReusableView *_Nonnull)viewForSupplementaryElementOfKind:(NSString *_Nonnull)kind atIndexPath:(NSIndexPath * _Nullable)indexPath
{
    NSParameterAssert([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind] || [kind isEqualToString:kDashboardErrorMessageSupplementaryKind]);
    UINib *nib = [self nibForViewForSupplementaryElementOfKind:kind];
    return [[nib instantiateWithOwner:self options:nil] firstObject];
}

- (void)configureView:(UICollectionReusableView *_Nonnull)view forSupplementaryElementOfKind:(NSString *_Nonnull)kind atIndexPath:(NSIndexPath * _Nullable)indexPath
{
    NSParameterAssert([kind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind] || [kind isEqualToString:kDashboardErrorMessageSupplementaryKind]);
}

- (void)configureCell:(UICollectionViewCell *_Nonnull)cell forItemAtIndexPath:(NSIndexPath * _Nullable)indexPath
{
    NSAssertNotImplemented();
}

- (SBRequest * _Nonnull)request
{
    SBRequest *request = [self dataLoadingRequest];
    [[SBCache cache] invalidateCacheForRequest:request];
    @synchronized(self) {
        self.callbacks[request.GUID] = [request.callback copy];
    }
    request.callback = ^(SBResponse *response) {
        self.error = response.error;
        @synchronized(self) {
            if (self.callbacks[response.requestGUID]) {
                self.callbacks[response.requestGUID](response);
                [self.callbacks removeObjectForKey:response.requestGUID];
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(dashboardWidget:didFinishDataLoadingWithResponse:)]) {
            [self.delegate dashboardWidget:self didFinishDataLoadingWithResponse:response];
        }
        if (self.dataUpdateStrategy) {
            [self.dataUpdateStrategy widgetDidFinishDataLoading];
        }
    };
    return request;
}

- (void)loadData
{
    if ([self isLoading]) {
        return;
    }
    NSAssert([SBSession defaultSession] != nil, @"No active session");
    self.loading = YES;
    [[SBSession defaultSession] performReqeust:[self request]];
    if (self.delegate) {
        [self.delegate dashboardWidgetDidStartDataLoading:self];
    }
}

- (void)reloadData
{
    if ([self isLoading]) {
        return;
    }
    [[SBSession defaultSession] performReqeust:[self request]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dashboardWidgetDidStartDataReloading:)]) {
        [self.delegate dashboardWidgetDidStartDataReloading:self];
    }
}

- (NSOperation<SBRequestProtocol> *_Nonnull)dataLoadingRequest
{
    NSAssertNotImplemented();
    return nil;
}

- (NSUInteger)numberOfItems
{
    return 0;
}

- (id _Nullable)itemAtIndexPath:(NSIndexPath *_Nonnull)indexPath
{
    return nil;
}

@end
