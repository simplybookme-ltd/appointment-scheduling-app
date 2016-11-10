//
//  DashboardSegmentedWidgetDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardSegmentedWidgetDataSource.h"
#import "SegmentedWidgetHeaderCollectionReusableView.h"

NSString * const kDashboardSegmentedWidgetHeaderSupplementaryKind = @"kDashboardSegmentedWidgetHeaderSupplementaryKind";
NSString * const kDashboardSegmentedWidgetHeaderSupplementaryReuseIdentifier = @"kDashboardSegmentedWidgetHeaderSupplementaryReuseIdentifier";

@interface DashboardSegmentedWidgetDataSource ()
{
    NSMutableDictionary *segmentsRequests;
}

@property (nonatomic, strong) NSMutableArray *_segments;
@property (nonatomic, readwrite) NSUInteger selectedSegmentIndex;

@end

@implementation DashboardSegmentedWidgetDataSource

@dynamic delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        segmentsRequests = [NSMutableDictionary dictionary];
        self._segments = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)segments
{
    return self._segments;
}

- (DashboardSegmentDataSource *)selectedSegment
{
    NSAssert(self.selectedSegmentIndex <= self._segments.count, @"trying to select not existing segment");
    return self._segments[self.selectedSegmentIndex];
}

- (BOOL)isLoading
{
    return [self.selectedSegment isLoading];
}

- (BOOL)isDataLoaded
{
    return [self.selectedSegment isDataLoaded];
}

- (BOOL)isDataEmpty
{
    return [self.selectedSegment isDataEmpty];
}

- (void)addSegmentDataSource:(DashboardSegmentDataSource *)segmentDataSource
{
    segmentDataSource.parent = self;
    [self._segments addObject:segmentDataSource];
}

- (void)selectSegmentAtIndex:(NSUInteger)segmentIndex
{
    NSUInteger previousSectionIndex = self.selectedSegmentIndex;
    self.selectedSegmentIndex = segmentIndex;
    if (self.delegate) {
        [self.delegate dashboardSegmentedWidget:self didSelectSegmentWithIndex:segmentIndex previouslySelectedSegmentIndex:previousSectionIndex];
    }
}

- (void)changeSegmentedControlValueAction:(UISegmentedControl *)segmentedControl
{
    [self selectSegmentAtIndex:segmentedControl.selectedSegmentIndex];
}

- (UINib *)nibForViewForSupplementaryElementOfKind:(NSString *_Nonnull)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [UINib nibWithNibName:@"SegmentedWidgetHeaderCollectionReusableView" bundle:nil];
    }
    return [super nibForViewForSupplementaryElementOfKind:kind];
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForViewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader]
     forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
            withReuseIdentifier:kDashboardSegmentedWidgetHeaderSupplementaryReuseIdentifier];
    [super configureReusableViewsForCollectionView:collectionView];
}

- (NSString *)reusableIdentifierForSupplementaryViewOnKind:(NSString *)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return kDashboardSegmentedWidgetHeaderSupplementaryReuseIdentifier;
    }
    return [super reusableIdentifierForSupplementaryViewOnKind:kind];
}

- (UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UINib *nib = [self nibForViewForSupplementaryElementOfKind:kind];
        return [[nib instantiateWithOwner:self options:nil] firstObject];
    }
    return [super viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (void)configureView:(SegmentedWidgetHeaderCollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        view.backgroundColor = self.color;
        [view setTitle:self.title];
        [view.segmentedControl removeAllSegments];
        for (NSUInteger i = 0; i < self._segments.count; i++) {
            DashboardSegmentDataSource *sectionDataSource = self._segments[i];
            [view.segmentedControl insertSegmentWithTitle:sectionDataSource.title atIndex:i animated:NO];
        }
        view.segmentedControl.selectedSegmentIndex = self.selectedSegmentIndex;
        [view.segmentedControl addTarget:self action:@selector(changeSegmentedControlValueAction:) forControlEvents:UIControlEventValueChanged];
    }
    else {
        [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

- (void)loadData
{
    [super loadData];
    self.selectedSegment.loading = YES;
}

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [self.selectedSegment dataLoadingRequest];
    @synchronized(self) {
        if (request.GUID && request.callback) {
            segmentsRequests[request.GUID] = [request.callback copy];
        }
    }
    return request;
}

- (void)applyDataFromResponse:(SBResponse *)response
{
    @synchronized(self) {
        SBRequestCallback callback = segmentsRequests[response.requestGUID];
        callback(response);
    }
}

- (NSUInteger)numberOfItems
{
    return self.selectedSegment.items.count;
}

@end
