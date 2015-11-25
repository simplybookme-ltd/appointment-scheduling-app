//
//  PieChartCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

@interface PieChartCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet XYPieChart *pieChart;
@property (nonatomic, weak) IBOutlet UILabel *primaryValueLabel;

- (void)addValue:(NSNumber *)value withLabel:(NSString *)label color:(UIColor *)color;

@end
