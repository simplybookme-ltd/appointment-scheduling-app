//
//  FilterListSelectorViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "FilterListSelectorViewController.h"

@interface FilterListSelectorViewController () <UISearchResultsUpdating>

@property (nonatomic, strong) NSNumber *anyItemEnabled;
@property (nonatomic, strong) NSArray <NSObject<FilterListSelectorItemProtocol> *> *filteredData;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation FilterListSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.definesPresentationContext = YES;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.filterListSelectorDelegate filterListSelectorWillDisappear:self];
}

#pragma mark -

- (NSNumber *)anyItemEnabled
{
    if (!_anyItemEnabled) {
        _anyItemEnabled = @([self.filterListSelectorDelegate isAnyItemEnabledForFilterListSelector:self]);
    }
    return _anyItemEnabled;
}

- (BOOL)isAnyItemEnabled
{
    return self.anyItemEnabled.boolValue;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.filteredData.count;
    }
    return self.collection.count + ([self isAnyItemEnabled] ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (self.searchController.active) {
        cell.textLabel.text = self.filteredData[indexPath.row].name;
    } else {
        if (indexPath.row == 0 && [self isAnyItemEnabled]) {
            cell.textLabel.text = NSLS(@"Any",@"");
            cell.detailTextLabel.text = @"";
        } else {
            cell.textLabel.text = self.collection[indexPath.row - ([self isAnyItemEnabled] ? 1 : 0)].title;
            cell.detailTextLabel.text = self.collection[indexPath.row - ([self isAnyItemEnabled] ? 1 : 0)].subtitle;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchController.active) {
        [self.filterListSelectorDelegate filterListSelector:self didSelectItem:self.filteredData[indexPath.row]];
    }
    else {
        if (indexPath.row == 0 && [self isAnyItemEnabled]) {
            [self.filterListSelectorDelegate filterListSelector:self didSelectItem:nil];
        }
        else {
            [self.filterListSelectorDelegate filterListSelector:self didSelectItem:self.collection[indexPath.row - ([self isAnyItemEnabled] ? 1 : 0)]];
        }
    }
    self.searchController.active = NO;
}

#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (!searchController.active) {
        [self.tableView reloadData];
        return;
    }
    if ([searchController.searchBar.text isEqualToString:@""] || !searchController.searchBar.text) {
        self.filteredData = [self.collection allObjects];
    }
    else {
        self.filteredData = [self.collection objectsPassingTest:^BOOL(NSObject<FilterListSelectorItemProtocol> * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            return [object.title rangeOfString:searchController.searchBar.text options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
    }
    [self.tableView reloadData];
}

@end
