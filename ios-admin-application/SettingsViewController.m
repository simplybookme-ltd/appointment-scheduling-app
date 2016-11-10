//
//  SettingsViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SettingsViewController.h"
#import "ACHSwitchTableViewCell.h"
#import "SBSession.h"
#import "SBSettings.h"
#import "AppDelegate.h"
#import "SBSessionManager.h"
#import "ACHKeyValueTableViewCell.h"
#import "LSManagedObjectContext.h"
#import "LSPerformer.h"
#import "LSBooking.h"
#import "LSBookingStatus.h"

NS_ENUM(NSInteger, SettingsSections)
{
    InfoSection,
    GeneralSection,
    ActionsSection,
    SettingsSectionsCount
};

NS_ENUM(NSInteger, InfoSectionItems)
{
    CompanyLoginItem,
    UserLoginItem,
    AppVersionItem,
    InfoSectionItemsCount
};

NS_ENUM(NSInteger, GeneralSectionItems)
{
    PushNotificationsItem,
    GeneralSectionItemsCount
};

NS_ENUM(NSInteger, ActionsSectionItems)
{
    LogoutActionItem,
    ActionsSectionItemsCount
};

@interface SettingsViewController () <UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL notificationStatusLoading;
@property (nonatomic) BOOL observing;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tableView registerClass:[ACHSwitchTableViewCell class] forCellReuseIdentifier:@"checkbox-cell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHKeyValueTableViewCell" bundle:nil] forCellReuseIdentifier:@"key-value-cell"];
    [[[SBSession defaultSession] settings] addObserver:self forKeyPath:kSBSettingsDeviceTokenKey options:0 context:NULL];
    [[[SBSession defaultSession] settings] addObserver:self forKeyPath:kSBSettingsNotificationsEnabledKey options:0 context:NULL];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(notificationStatusLoading)) options:0 context:NULL];
    self.observing = YES;
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)removeObservers
{
    if (self.observing) {
        [[[SBSession defaultSession] settings] removeObserver:self forKeyPath:kSBSettingsDeviceTokenKey context:NULL];
        [[[SBSession defaultSession] settings] removeObserver:self forKeyPath:kSBSettingsNotificationsEnabledKey context:NULL];
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(notificationStatusLoading)) context:NULL];
        self.observing = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == NULL) {
        if ([keyPath isEqualToString:kSBSettingsDeviceTokenKey]
            || [keyPath isEqualToString:kSBSettingsNotificationsEnabledKey]
            || [keyPath isEqualToString:NSStringFromSelector(@selector(notificationStatusLoading))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PushNotificationsItem inSection:GeneralSection]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

#pragma mark - Actions

- (void)togglePushNotificationsSwitcherAction:(UISwitch *)sender
{
    SBSession *session = [SBSession defaultSession];
    NSString *deviceToken = [[session settings] objectForKey:kSBSettingsDeviceTokenKey];
    if (deviceToken && !sender.on) {
        SBRequest *request = [session deleteDeviceToken:deviceToken callback:^(SBResponse *response) {
            if (response.error) {
                if (!response.canceled) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                                       message:NSLS(@"An error occurred during applying settings. Please try again later.",@"")
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
            else {
                [[SBSession defaultSession].settings setObject:@NO forKey:kSBSettingsNotificationsEnabledKey];
                [[UIApplication sharedApplication] unregisterForRemoteNotifications];
            }
            self.notificationStatusLoading = NO;
        }];
        self.notificationStatusLoading = YES;
        [session performReqeust:request];
    } else if (deviceToken && sender.on) {
        SBRequest *request = [session addDeviceToken:deviceToken callback:^(SBResponse *response) {
            if (response.error) {
                if (!response.canceled) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                                       message:NSLS(@"An error occurred during applying settings. Please try again later.",@"")
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
            else {
                [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                [[SBSession defaultSession].settings setObject:@YES forKey:kSBSettingsNotificationsEnabledKey];
            }
            self.notificationStatusLoading = NO;
        }];
        self.notificationStatusLoading = YES;
        [session performReqeust:request];
    } else if (!deviceToken && sender.on) {
        [(AppDelegate *)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    }
}

- (IBAction)termsAction:(id)sender
{
    [self performSegueWithIdentifier:@"terms" sender:nil];
}

#pragma mark - Table view datesource/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SettingsSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case InfoSection:
            return InfoSectionItemsCount;
        case GeneralSection:
            return GeneralSectionItemsCount;
        case ActionsSection:
            return ActionsSectionItemsCount;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == GeneralSection) {
        ACHSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"checkbox-cell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switch (indexPath.row) {
            case PushNotificationsItem:
            {
                cell.textLabel.text = NSLS(@"Send push notifications",@"");
                if (self.notificationStatusLoading) {
                    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activityIndicator startAnimating];
                    cell.accessoryView = activityIndicator;
                } else {
                    cell.accessoryView = cell.switcher;
                    SBSettings *settings = [[SBSession defaultSession] settings];
                    cell.switcher.on = [[settings objectForKey:kSBSettingsNotificationsEnabledKey] boolValue] && [settings objectForKey:kSBSettingsDeviceTokenKey] && [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
                    [cell.switcher addTarget:self action:@selector(togglePushNotificationsSwitcherAction:) forControlEvents:UIControlEventValueChanged];
                }
            }
                break;
        }
        return cell;
    }
    else if (indexPath.section == ActionsSection) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"action-cell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        switch (indexPath.row) {
            case LogoutActionItem:
                cell.textLabel.text = NSLS(@"Logout",@"");
                break;
        }
        return cell;
    }
    else if (indexPath.section == InfoSection) {
        ACHKeyValueTableViewCell *cell = (ACHKeyValueTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"key-value-cell"
                                                                                                     forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switch (indexPath.row) {
            case CompanyLoginItem:
                cell.titleLabel.text = NSLS(@"Company:", @"");
                cell.valueLabel.text = [SBSession defaultSession].user.credentials.companyLogin;
                break;
            case UserLoginItem:
                cell.titleLabel.text = NSLS(@"Login:", @"");
                cell.valueLabel.text = [SBSession defaultSession].user.login;
                break;
            case AppVersionItem: {
                cell.titleLabel.text = NSLS(@"Version:", @"");
                NSString *versionString = [NSString stringWithFormat:@"%@ (%@)",
                                                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
                cell.valueLabel.text = versionString;
            }
                break;
            default:break;
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == ActionsSection) {
        if (indexPath.row == LogoutActionItem) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"SimplyBook.me",@"")
                                                                           message:NSLS(@"Do you want to log out?",@"")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"NO",@"") style:UIAlertActionStyleDefault handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"YES",@"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self logoutAction];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark - Alert view delegate

- (void)logoutAction
{
    [[SBCache cache] flush];
    [self removeObservers];
    
    SBSessionManager *manager = [SBSessionManager sharedManager];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    NSString *deviceToke = [manager.defaultSession.settings objectForKey:kSBSettingsDeviceTokenKey];
    if (deviceToke != nil && [deviceToke isKindOfClass:[NSString class]] && ![deviceToke isEqualToString:@""]) {
        SBRequest *request = [manager.defaultSession deleteDeviceToken:deviceToke callback:^(SBResponse<id> * _Nonnull response) {
            // nothing to do
        }];
        [manager.defaultSession performReqeust:request];
    }
    [manager endSession:manager.defaultSession];
    [self removeLocalStoredData];
}

- (void)removeLocalStoredData
{
    LSManagedObjectContext *context = [[LSManagedObjectContext alloc] init];
    NSArray *objects = [context fetchObjectOfEntity:NSStringFromClass([LSPerformer class]) withPredicate:nil error:nil];
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    objects = [context fetchObjectOfEntity:NSStringFromClass([LSBooking class]) withPredicate:nil error:nil];
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    objects = [context fetchObjectOfEntity:NSStringFromClass([LSBookingStatus class]) withPredicate:nil error:nil];
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    [context save:nil];
}

@end
