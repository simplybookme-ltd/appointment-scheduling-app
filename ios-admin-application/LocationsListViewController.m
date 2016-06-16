//
//  ClientListViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "LocationsListViewController.h"
#import "SBSession.h"
#import "NSError+SimplyBook.h"

@interface LocationsListViewController ()
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, strong) NSArray *list;

@end

@implementation LocationsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    pendingRequests = [NSMutableArray array];
    
    SBRequest *request = [[SBSession defaultSession] getLocationsWithCallback:^(SBResponse<NSArray <NSDictionary *> *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            if (response.error && !response.canceled) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                               message:NSLS(@"Information about locations not loaded.",@"")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                if (self.unitID) {
                    self.list = [response.result objectsAtIndexes:[response.result indexesOfObjectsPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        return [obj[@"units"] containsObject:self.unitID];
                    }]];
                } else {
                    self.list = response.result;
                }
                [self.tableView reloadData];
            }
        });
    }];
    [pendingRequests addObject:request.GUID];
    [self.activityIndicator startAnimating];
    [[SBSession defaultSession] performReqeust:request];
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
    NSDictionary *location = self.list[indexPath.row];
    NSString *detailsString = @"";
    NSString *clue = @"";
    if (location[@"city"] && ![location[@"city"] isEqualToString:@""]) {
        detailsString = location[@"city"];
        clue = @", ";
    }
    if (location[@"address1"] && ![location[@"address1"] isEqualToString:@""]) {
        detailsString = [detailsString stringByAppendingFormat:@"%@%@", clue, location[@"address1"]];
        clue = @", ";
    }
    if (location[@"address2"] && ![location[@"address2"] isEqualToString:@""]) {
        detailsString = [detailsString stringByAppendingFormat:@"%@%@", clue, location[@"address2"]];
        clue = @", ";
    }
    cell.textLabel.text = location[@"title"];
    cell.detailTextLabel.text = detailsString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[SBSession defaultSession] cancelRequests:pendingRequests];
    if (self.locationSelectedHandler) {
        self.locationSelectedHandler(self.list[indexPath.row]);
    }
}

@end
