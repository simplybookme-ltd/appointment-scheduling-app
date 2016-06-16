//
//  FilterViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 26.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "FilterViewController.h"
#import "ACHKeyValueTableViewCell.h"
#import "SBSession.h"
#import "FilterListSelectorViewController.h"
#import "SBPerformer.h"
#import "SBPerformer+FilterListSelector.h"
#import "SBService.h"
#import "SBService+FilterListSelector.h"

static NSString *const filterListSelectorSegue = @"filterList";

NS_ENUM(NSInteger, FilterRows)
{
    FilterEventRow,
    FilterUnitRow,
    FilterTypeRow,
    
    FilterRowsCount,
    FilterTypeSelectorExpandedRowsCount = FilterRowsCount + 1,
};

static NSString *const kPickerTableViewCellIdentifier = @"kPickerTableViewCellIdentifier";
static NSString *const kKeyValueTableViewCellIdentifier = @"kKeyValueTableViewCellIdentifier";
static NSString *const kResetTableViewCellIdentifier = @"kResetTableViewCellIdentifier";
static NSInteger const kPickerViewTag = 100;

@interface FilterViewController () <FilterListSelectorDelegate>

@property (nonatomic, getter=isTypeSelectorExpanded) BOOL typeSelectorExpanded;
@property (nonatomic, strong) SBGetBookingsFilter *filter;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) SBPerformersCollection *performers;
@property (nonatomic, strong) SBServicesCollection *services;
@property (nonatomic, strong) SBRequest *getPerformersRequest;
@property (nonatomic, strong) SBRequest *getServicesRequest;

@end

@implementation FilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.filter = (self.initialFilter ? [self.initialFilter copy] : [SBGetBookingsFilter todayBookingsFilter]);
    
    self.tableView.estimatedRowHeight = 40;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    SBSession *session = [SBSession defaultSession];
    self.getPerformersRequest = [session getUnitList:^(SBResponse <SBPerformersCollection *> *response) {
        if (!response.error) {
            SBUser *user = [SBSession defaultSession].user;
            NSAssert(user != nil, @"no user found");
            if ([user hasAccessToACLRule:SBACLRulePerformersFullListAccess]) {
                self.performers = response.result;
            } else {
                NSAssert(user.associatedPerformerID != nil && ![user.associatedPerformerID isEqualToString:@""], @"invalid associated performer value");
                self.performers = [response.result collectionWithObjectsPassingTest:^BOOL(SBPerformer * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                    *stop = [object.performerID isEqualToString:user.associatedPerformerID];
                    return *stop;
                }];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
                if (selectedRow && selectedRow.row == FilterUnitRow) {
                    [self performSegueWithIdentifier:filterListSelectorSegue sender:self];
                }
            });
        } else if ([self.tableView indexPathForSelectedRow] && !response.canceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:NSLS(@"An error occurred. Please try again later.", @"")
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
        self.getPerformersRequest = nil;
    }];
    [session performReqeust:self.getPerformersRequest];
    
    self.getServicesRequest = [session getEventList:^(SBResponse <SBServicesCollection *> *response) {
        if (!response.error) {
            self.services = response.result;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activityIndicator.hidden = YES;
                NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
                if (selectedRow && selectedRow.row == FilterEventRow) {
                    [self performSegueWithIdentifier:filterListSelectorSegue sender:self];
                }
            });
        } else if ([self.tableView indexPathForSelectedRow] && !response.canceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:NSLS(@"An error occurred. Please try again later.", @"")
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
        self.getServicesRequest = nil;
    }];
    [session performReqeust:self.getServicesRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)typeSelectorRowIndex
{
    return [self isTypeSelectorExpanded] ? FilterTypeRow + 1 : FilterTypeRow;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self isTypeSelectorExpanded] ? FilterTypeSelectorExpandedRowsCount : FilterRowsCount;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case FilterEventRow:
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kKeyValueTableViewCellIdentifier forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLS(@"Service",@"");
                cell.detailTextLabel.text = (self.filter.eventID) ? self.services[self.filter.eventID].name : NSLS(@"Any",@"");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                return cell;
            }
            case FilterUnitRow:
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kKeyValueTableViewCellIdentifier forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLS(@"Performer",@"");
                cell.detailTextLabel.text = (self.filter.unitGroupID) ? self.performers[self.filter.unitGroupID].name : NSLS(@"Any",@"");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                return cell;
            }
            case FilterTypeRow:
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kKeyValueTableViewCellIdentifier forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = NSLS(@"Type",@"");
                cell.detailTextLabel.text = [self.filter titleForBookingTypeOptionAtIndex:self.filter.bookingType.integerValue];
                return cell;
            }
        }
        if ([self isTypeSelectorExpanded] && indexPath.row == [self typeSelectorRowIndex]) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPickerTableViewCellIdentifier forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UIPickerView *pickerView = (UIPickerView *)[cell.contentView viewWithTag:kPickerViewTag];
            [pickerView setDelegate:self];
            [pickerView setDataSource:self];
            [pickerView selectRow:self.filter.bookingType.integerValue inComponent:0 animated:NO];
            return cell;
        }
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kResetTableViewCellIdentifier forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [self.filter reset];
        [self applyFilterWithReset:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if ([self isTypeSelectorExpanded]) {
        NSInteger rowToRemove = [self typeSelectorRowIndex];
        self.typeSelectorExpanded = NO;
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowToRemove inSection:0]]
                              withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:FilterTypeRow -1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if (indexPath.row == FilterTypeRow) {
        self.typeSelectorExpanded = YES;
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self typeSelectorRowIndex] inSection:0]]
                              withRowAnimation:UITableViewRowAnimationTop];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if (indexPath.row == FilterUnitRow) {
        if (!self.performers && self.getPerformersRequest) {
            self.activityIndicator.hidden = NO;
        } else {
            [self performSegueWithIdentifier:filterListSelectorSegue sender:self];
        }
    }
    else if (indexPath.row == FilterEventRow) {
        if (!self.services && self.getServicesRequest) {
            self.activityIndicator.hidden = NO;
        } else {
            [self performSegueWithIdentifier:filterListSelectorSegue sender:self];
        }
    }
}

#pragma mark -

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.filter numberOfBookingTypeOptions];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.filter titleForBookingTypeOptionAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.filter.bookingType = @(row);
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:FilterTypeRow inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -

- (IBAction)cancelAction:(id)sender
{
    [self.delegate filterControllerDidCancel:self];
}

- (IBAction)applyAction:(id)sender
{
    [self applyFilterWithReset:NO];
}

- (void)applyFilterWithReset:(BOOL)reset
{
    [self.delegate filterController:self didSetNewFilter:self.filter reset:reset];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:filterListSelectorSegue]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSAssert(indexPath != nil, @"performer or service row should be selected");
        FilterListSelectorViewController *controller = segue.destinationViewController;
        controller.filterListSelectorDelegate = self;
        if (indexPath.row == FilterUnitRow) {
            controller.collection = self.performers;
        }
        else if (indexPath.row == FilterEventRow) {
            controller.collection = self.services;
        }
        else {
            NSAssert(NO, @"unexpected row selected %ld", (long)indexPath.row);
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Filter List Selector Delegate

- (NSString *)titleForAnyItemInFilterListSelector:(FilterListSelectorViewController *)selector
{
    if (selector.collection == self.performers) {
        return NSLS(@"Any Performer",@"");
    }
    else {
        return NSLS(@"Any Service",@"");
    }
}

- (BOOL)isAnyItemEnabledForFilterListSelector:(FilterListSelectorViewController *)selector
{
    return YES;
}

- (void)filterListSelector:(FilterListSelectorViewController *)selector didSelectItem:(nullable NSObject<FilterListSelectorItemProtocol> *)item
{
    if (selector.collection == self.performers) {
        self.filter.unitGroupID = item.itemID;
    }
    else {
        self.filter.eventID = item.itemID;
    }
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView reloadData];
}

- (void)filterListSelectorWillDisappear:(FilterListSelectorViewController *)selector
{
}

@end
