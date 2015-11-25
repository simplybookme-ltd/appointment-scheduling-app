//
//  LoginViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "LoginViewController.h"
#import "ACHTextFieldTableViewCell.h"
#import "SBSessionManager.h"
#import "SBSessionCredentials.h"
#import "NSError+SimplyBook.h"
#import "FXKeychain.h"

NS_ENUM(NSInteger, LoginFormFields)
{
    CompanyLoginFormField,
    UserLoginFormField,
    PasswordFormField,
    KeychainFormField,
    LoginFormFieldsCount,
    
    ValidationFieldsIteratorStart = CompanyLoginFormField,
    ValidationFieldsIteratorEnd = PasswordFormField
};

@interface LoginViewController () <SBSessionManagerDelegateObserver>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic) BOOL savePasswordToKeychain;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHTextFieldTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"checkbox-cell"];
    
    [[SBSessionManager sharedManager] addObserver:self];
    self.savePasswordToKeychain = YES;
}

- (void)dealloc
{
    [[SBSessionManager sharedManager] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:CompanyLoginFormField inSection:0]] becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (UITextField *)textFieldForIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    return cell.textField;
}

- (NSInteger)tagForTextFieldAtRowIndex:(NSInteger)row
{
    return row + 100;
}

- (NSInteger)rowIndexForTextFieldWithTag:(NSInteger)tag
{
    return tag - 100;
}

- (void)blockFormAnimated:(BOOL)animated
{
    for (NSInteger i = 0; i < LoginFormFieldsCount; i++) {
        if (i == KeychainFormField) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [(UISwitch *)cell.accessoryView setEnabled:NO];
        } else {
            UITextField *textField = [self textFieldForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [textField resignFirstResponder];
            textField.enabled = NO;
        }
    }
    if (animated) {
        [UIView animateWithDuration:.3 delay:0
             usingSpringWithDamping:.5 initialSpringVelocity:0 options:0
                         animations:^{
                             self.loginButton.hidden = YES;
                             self.activityView.hidden = NO;
                         }
                         completion:^(BOOL finished) {
                             self.loginButton.hidden = YES;
                             self.activityView.hidden = NO;
                         }];
    } else {
        self.loginButton.hidden = YES;
        self.activityView.hidden = NO;
    }
}

- (void)unblockFormAnimated:(BOOL)animated
{
    for (NSInteger i = 0; i < LoginFormFieldsCount; i++) {
        if (i == KeychainFormField) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [(UISwitch *)cell.accessoryView setEnabled:YES];
        } else {
            UITextField *textField = [self textFieldForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            textField.enabled = YES;
        }
    }
    if (animated) {
        [UIView animateWithDuration:.3 delay:0
             usingSpringWithDamping:.5 initialSpringVelocity:0 options:0
                         animations:^{
                             self.loginButton.hidden = NO;
                             self.activityView.hidden = YES;
                         }
                         completion:^(BOOL finished) {
                             self.loginButton.hidden = NO;
                             self.activityView.hidden = YES;
                         }];
    } else {
        self.loginButton.hidden = NO;
        self.activityView.hidden = YES;
    }
}

- (void)toggleSavePasswordAction:(UISwitch *)switcher
{
    self.savePasswordToKeychain = switcher.on;
}

#pragma mark -

- (IBAction)loginAction:(id)sender
{
    for (NSInteger i = ValidationFieldsIteratorStart; i <= ValidationFieldsIteratorEnd; i++) {
        UITextField *textField = [self textFieldForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [textField resignFirstResponder];
        if (!textField.text || [textField.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"SimplyBook.me",@"")
                                                            message:NSLS(@"Please fill all fields.",@"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLS(@"OK",@"")
                                                  otherButtonTitles:nil];
            alert.tag = [self tagForTextFieldAtRowIndex:i];
            [alert show];
            return;
        }
    }
    [self blockFormAnimated:YES];
    NSString *companyLogin = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:CompanyLoginFormField inSection:0]] text];
    NSString *userLogin = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:UserLoginFormField inSection:0]] text];
    NSString *password = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:PasswordFormField inSection:0]] text];
    SBSessionCredentials *credentials = [SBSessionCredentials credentialsForCompanyLogin:companyLogin userLogin:userLogin password:password];
    [[SBSessionManager sharedManager] startSessionWithCredentials:credentials];
}

- (IBAction)restorePasswordAction:(id)sender
{
    NSString *restorePasswordURLString = @"https://secure.simplybook.me/login/remind/company/";
    NSString *companyLogin = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:CompanyLoginFormField inSection:0]] text];
    if (companyLogin && ![companyLogin isEqualToString:@""]) {
        restorePasswordURLString = [restorePasswordURLString stringByAppendingFormat:@"%@/", companyLogin];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:restorePasswordURLString]];
}

- (IBAction)restoreCompanyLoginAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://secure.simplybook.me/login/remind-company/"]];
}

#pragma mark -

- (ACHTextFieldTableViewCell *)dequeueTextFieldCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textField.delegate = self;
    cell.textField.tag = [self tagForTextFieldAtRowIndex:indexPath.row];
    return cell;
}

- (UITableViewCell *)dequeueCheckboxCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"checkbox-cell" forIndexPath:indexPath];
    if (!cell.accessoryView) {
        cell.accessoryView = [UISwitch new];
        UISwitch *switcher = (UISwitch *)cell.accessoryView;
        [switcher addTarget:self action:@selector(toggleSavePasswordAction:) forControlEvents:UIControlEventValueChanged];
        switcher.on = self.savePasswordToKeychain;
    }
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return LoginFormFieldsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SBSessionCredentials *credentials = [SBSessionCredentials credentialsFromKeychain:[FXKeychain defaultKeychain]];
    if (indexPath.row == CompanyLoginFormField) {
        ACHTextFieldTableViewCell *cell = [self dequeueTextFieldCellForTableView:tableView indexPath:indexPath];
        cell.textField.placeholder = NSLS(@"Company Login",@"");
        cell.textField.returnKeyType = UIReturnKeyNext;
        cell.textField.keyboardType = UIKeyboardTypeASCIICapable;
        cell.textField.autocorrectionType = UITextAutocapitalizationTypeNone;
        if (credentials) {
            cell.textField.text = credentials.companyLogin;
        }
        return cell;
    }
    else if (indexPath.row == UserLoginFormField) {
        ACHTextFieldTableViewCell *cell = [self dequeueTextFieldCellForTableView:tableView indexPath:indexPath];
        cell.textField.placeholder = NSLS(@"Login",@"");
        cell.textField.returnKeyType = UIReturnKeyNext;
        cell.textField.keyboardType = UIKeyboardTypeAlphabet;
        if (credentials) {
            cell.textField.text = credentials.userLogin;
        }
        return cell;
    }
    else if (indexPath.row == PasswordFormField) {
        ACHTextFieldTableViewCell *cell = [self dequeueTextFieldCellForTableView:tableView indexPath:indexPath];
        cell.textField.placeholder = NSLS(@"Password",@"");
        cell.textField.secureTextEntry = YES;
        cell.textField.returnKeyType = UIReturnKeyGo;
        cell.textField.keyboardType = UIKeyboardTypeAlphabet;
        if (credentials) {
            cell.textField.text = credentials.password;
        }
        return cell;
    }
    else if (indexPath.row == KeychainFormField) {
        UITableViewCell *cell = [self dequeueCheckboxCellForTableView:tableView indexPath:indexPath];
        cell.textLabel.text = NSLS(@"Save password to keychain",@"");
        cell.textLabel.numberOfLines = 2;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row != KeychainFormField) {
        [[self textFieldForIndexPath:indexPath] becomeFirstResponder];
    }
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger rowIndex = [self rowIndexForTextFieldWithTag:textField.tag];
    if (rowIndex < PasswordFormField) {
        [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:rowIndex+1 inSection:0]] becomeFirstResponder];
    } else {
        [self loginAction:nil];
    }
    return YES;
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger rowIndex = [self rowIndexForTextFieldWithTag:alertView.tag];
    [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0]] becomeFirstResponder];
}

#pragma mark -

- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([error.domain isEqualToString:SBSessionManagerErrorDomain] && error.code == SBWrongCredentialsErrorCode) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                            message:[error message]
                                                           delegate:self
                                                  cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
            alert.tag = [self tagForTextFieldAtRowIndex:CompanyLoginFormField];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                            message:[error message]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
            [alert show];
        }
        [self unblockFormAnimated:YES];
    });
}

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session
{
    NSString *companyLogin = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:CompanyLoginFormField inSection:0]] text];
    NSString *userLogin = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:UserLoginFormField inSection:0]] text];
    NSString *password = [[self textFieldForIndexPath:[NSIndexPath indexPathForItem:PasswordFormField inSection:0]] text];
    SBSessionCredentials *credentials = [SBSessionCredentials credentialsForCompanyLogin:companyLogin userLogin:userLogin password:password];
    if (self.savePasswordToKeychain) {
        [credentials saveToKeychain:[FXKeychain defaultKeychain]];
    }
    else {
        [credentials removeFromKeychain:[FXKeychain defaultKeychain]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"loginToInitSegue" sender:nil];
    });

}

- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session
{
    // nothing to do
}

- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin
{
    // nothing to do
}

@end
