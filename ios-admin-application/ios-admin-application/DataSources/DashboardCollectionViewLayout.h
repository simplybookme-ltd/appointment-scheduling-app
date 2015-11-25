//
//  DashboardCollectionViewLayout.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kDashboardWidgetBackgroundDecorationViewKind;
extern NSString * const kDashboardWidgetSeparatorDecorationViewKind;

typedef NS_ENUM(NSUInteger, DashboardCollectionViewLayoutSectionDirection)
{
    DashboardCollectionViewLayoutHorizontalSectionDirection,
    DashboardCollectionViewLayoutVerticalSectionDirection
};

typedef NS_ENUM(NSUInteger, DashboardCollectionViewLayoutWidgetLayout)
{
    DashboardCollectionViewLayoutFullWidthWidgetLayout,
    DashboardCollectionViewLayoutHalfWidthWidgetLayout
};

@class DashboardCollectionViewLayout;

@protocol DashboardCollectionViewLayoutProtocol <NSObject>

- (CGFloat)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout heightForSupplementaryViewOfKind:(NSString *)kind inSection:(NSUInteger)section;
- (CGFloat)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout heightForCellForItemAtIndexPath:(NSIndexPath *)indexPath maxWidth:(CGFloat)maxWidth;
- (BOOL)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout shouldDisplayActivityIndicatorInSection:(NSUInteger)section;
- (BOOL)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout shouldDisplayErrorMessageInSection:(NSUInteger)section;
- (DashboardCollectionViewLayoutSectionDirection)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout directionForSection:(NSUInteger)section;
- (DashboardCollectionViewLayoutWidgetLayout)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout widgetLayoutForSection:(NSUInteger)section;

@end

@interface DashboardCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, weak) IBOutlet NSObject<DashboardCollectionViewLayoutProtocol> *delegate;
@property (nonatomic, weak) NSObject<UICollectionViewDataSource> *dataSource;

@end
