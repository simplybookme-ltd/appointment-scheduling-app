//
//  AddClientViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "AddClientViewController.h"
#import "ACHTextFieldTableViewCell.h"
#import "HMDiallingCode.h"
#import "SBSession.h"
#import "NSError+SimplyBook.h"
#import "SBRegExpValidator.h"

NS_ENUM(NSInteger, AddClientFormFields)
{
    AddClientNameFormField,
    AddClientPhoneFormField,
    AddClientEmailFormField,
    
    AddClientFormFieldsCount,
    AddClientFormFieldsIteratorBegin = AddClientNameFormField,
    AddClientFormFieldsIteratorEnd = AddClientEmailFormField
};

@interface AddClientViewController () <HMDiallingCodeDelegate>
{
    HMDiallingCode *diallingCodeDetector;
    NSString *diallingCode;
    SBRequest *addClientRequest;
}
@end

@implementation AddClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    diallingCode = @"+";
    diallingCodeDetector = [[HMDiallingCode alloc] initWithDelegate:self];
    [diallingCodeDetector getDiallingCodeForCountry:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
    [self.tableView registerNib:[UINib nibWithNibName:@"ACHTextFieldTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
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

- (IBAction)cancelAction:(id)sender
{
    if (addClientRequest) {
        [[SBSession defaultSession] cancelRequestWithID:addClientRequest.GUID];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneAction:(id)sender
{
    if ([self textFieldsValidation]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        NSString *name = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientNameFormField inSection:0]] text];
        NSString *phone = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientPhoneFormField inSection:0]] text];
        NSString *email = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientEmailFormField inSection:0]] text];
        addClientRequest = [[SBSession defaultSession] addClientWithName:name phone:phone email:email
                                                                  callback:^(SBResponse *response)
        {
            addClientRequest = nil;
            if (response.error) {
                if (response.canceled) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.activityView stopAnimating];
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.activityView stopAnimating];
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                        message:[response.error message]
                                                                       delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                              otherButtonTitles:nil];
                        [alert show];
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.clientCreatedHandler) {
                        self.clientCreatedHandler(@{@"id" : response.result, @"name" : name, @"phone" : phone, @"email" : email});
                    }
                    else {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                });
            }
        }];
        [self.activityView startAnimating];
        [[SBSession defaultSession] performReqeust:addClientRequest];
    }
}

#pragma mark - textField validation

- (UIAlertView *)alertWithTitle:(NSString*)title message:(NSString*)message {
    UIAlertView *alert =[[UIAlertView alloc ] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    return alert;
}

- (BOOL)textFieldsValidation {
    NSString *name = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientNameFormField inSection:0]] text];
    SBValidator *notEmptyStringValidarot = [SBValidator notEmptyStringValidator];
    if (![notEmptyStringValidarot isValid:name]) {
        UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Name", @"") message:NSLS(@"Please enter client name.", @"")];
        [alert show];
        return NO;
    }
    
    NSString *emailString = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientEmailFormField inSection:0]] text];
    SBValidator *emailValidator = [SBRegExpValidator emailAddressValidator];
    if ([notEmptyStringValidarot isValid:emailString]) {
        if(![emailValidator isValid:emailString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Email", @"") message:NSLS(@"Please enter valid email address.", @"")];
            [alert show];
            return NO;
        }
    }
    
    NSString *phoneString = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientPhoneFormField inSection:0]] text];
    SBValidator *phoneValidator = [SBRegExpValidator phoneNumberValidator:YES];
    if ([notEmptyStringValidarot isValid:phoneString]) {
        if(![phoneValidator isValid:phoneString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Phone", @"") message:NSLS(@"Please enter valid phone number.", @"")];
            [alert show];
            return NO;
        }
    }
    
    return [notEmptyStringValidarot isValid:phoneString] || [notEmptyStringValidarot isValid:emailString];
}

#pragma mark -

- (UITextField *)textFieldForIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    return cell.textField;
}

- (NSInteger)tagForRow:(NSInteger)row
{
    return row + 100;
}

- (NSInteger)rowForTag:(NSInteger)tag
{
    return tag - 100;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return AddClientFormFieldsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    switch (indexPath.row) {
        case AddClientNameFormField:
            cell.textField.placeholder = NSLS(@"Name",@"");
            cell.textField.keyboardType = UIKeyboardTypeAlphabet;
            cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case AddClientPhoneFormField:
            cell.textField.placeholder = NSLS(@"Phone Number",@"");
            cell.textField.keyboardType = UIKeyboardTypePhonePad;
            break;
        case AddClientEmailFormField:
            cell.textField.placeholder = NSLS(@"Email",@"");
            cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        default:
            NSAssertFail();
            break;
    }
    cell.textField.tag = [self tagForRow:indexPath.row];
    cell.textField.delegate = self;
    cell.textField.returnKeyType = (indexPath.row < AddClientFormFieldsIteratorEnd ? UIReturnKeyNext : UIReturnKeyDone);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell.textField becomeFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self rowForTag:textField.tag] == AddClientFormFieldsIteratorEnd) {
        [self doneAction:nil];
    }
    else {
        [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:[self rowForTag:textField.tag]+1 inSection:0]] becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (!textField.hasText && [self rowForTag:textField.tag] == AddClientPhoneFormField) {
        textField.text = diallingCode;
    }
    return YES;
}

#pragma mark -

- (void)didGetDiallingCode:(NSString *)_diallingCode forCountry:(NSString *)countryCode
{
    diallingCode = [NSString stringWithFormat:@"+%@", _diallingCode];
}

- (void)failedToGetDiallingCode
{
    diallingCode = @"+";
}

@end
