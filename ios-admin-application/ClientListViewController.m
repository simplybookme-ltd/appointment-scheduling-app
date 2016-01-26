//
//  ClientListViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "ClientListViewController.h"
#import "SBSession.h"
#import "NSError+SimplyBook.h"
#import "AddClientViewController.h"

#define kClientListSearchPatternKey @"kClientListSearchPatternKey"

@interface ClientListViewController () <UISearchResultsUpdating>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) SBRequest *searchRequest;
@property (nonatomic, strong) NSArray *list;

@end

@implementation ClientListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.definesPresentationContext = YES;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = NSLS(@"Name, Phone, Email", @"");
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.searchRequest = [self searchRequestWithPattern:@""];
    [self.activityIndicator startAnimating];
    [[SBSession defaultSession] performReqeust:self.searchRequest];
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

- (SBRequest *)searchRequestWithPattern:(NSString *)pattern
{
    SBRequest *request = [[SBSession defaultSession] getClientListWithPattern:pattern callback:^(SBResponse *response) {
        if (response.error) {
            if (!response.canceled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:[response.error message]
                                                                   delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            }
        } else {
            self.list = response.result;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
                [self.tableView reloadData];
            });
        }
    }];
    request.cachePolicy = SBNoCachePolicy;
    return request;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *client = self.list[indexPath.row];
    NSString *detailsString = [NSString stringWithFormat:@"%@, %@", client[@"email"], client[@"phone"]];
    if (self.searchController.active) {
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:client[@"name"]
                                                                                  attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
        [title setAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}
                       range:[client[@"name"] rangeOfString:self.searchController.searchBar.text options:NSCaseInsensitiveSearch]];
        cell.textLabel.attributedText = title;
        NSMutableAttributedString *description = [[NSMutableAttributedString alloc] initWithString:detailsString
                                                                                        attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
        [description setAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}
                             range:[detailsString rangeOfString:self.searchController.searchBar.text options:NSCaseInsensitiveSearch]];
        cell.detailTextLabel.attributedText = description;
    } else {
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:client[@"name"]
                                                                        attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
        cell.detailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:detailsString
                                                                              attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchRequest) {
        [[SBSession defaultSession] cancelRequestWithID:self.searchRequest.GUID];
    }
    if (self.clientSelectedHandler) {
        self.clientSelectedHandler(self.list[indexPath.row]);
    }
}

#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (!searchController.active) {
        [self.tableView reloadData];
        return;
    }
    if (![searchController.searchBar.text isEqualToString:@""] && searchController.searchBar.text) {
        SBSession *session = [SBSession defaultSession];
        if (self.searchRequest) {
            [session cancelRequestWithID:self.searchRequest.GUID];
        }
        self.searchRequest = [self searchRequestWithPattern:searchController.searchBar.text];
        [self.activityIndicator startAnimating];
        [session performReqeust:self.searchRequest];
    }
    [self.tableView reloadData];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AddClientViewController *contoller = segue.destinationViewController;
    contoller.clientCreatedHandler = self.clientSelectedHandler;
}

@end
