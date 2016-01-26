//
//  ACHAdditionalFieldsDataSource.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 10.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ACHAdditionalFieldsDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, getter=isReadOnly) BOOL readOnly;
@property (nonatomic, copy) NSString *cellReuseIdentifier;
@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) NSArray *additionalFields;

- (instancetype)initWithAdditionalFields:(NSArray *)additionalFields;
- (void)setAdditionalFields:(NSArray *)additionalFields;
- (void)configureTableView:(UITableView *)tableView;
- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

@end
