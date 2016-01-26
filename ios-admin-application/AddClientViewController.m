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
#import "SBCompanyInfo.h"

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
    NSMutableArray *pendingRequests;
    NSString *requiredFields;
    NSString *phone;
    NSString *email;
}

@property (nonatomic, strong) SBValidator *notEmptyStringValidarot;
@property (nonatomic, strong) SBValidator *emailValidator;
@property (nonatomic, strong) SBValidator *phoneValidator;

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
    
    pendingRequests = [NSMutableArray array];
    SBRequest *request = [[SBSession defaultSession] getCompanyParam:kSBCompanyClientRequiredFieldsParamKey callback:^(SBResponse<NSString *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        if (!response.error) {
            requiredFields = response.result;
        }
        else {
            // TODO: handle error
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    }];
    [pendingRequests addObject:request.GUID];
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

- (IBAction)cancelAction:(id)sender
{
    if (pendingRequests.count) {
        [[SBSession defaultSession] cancelRequests:pendingRequests];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneAction:(id)sender
{
    if ([self textFieldsValidation]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        NSString *name = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientNameFormField inSection:0]] text];
        NSString *_phone = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientPhoneFormField inSection:0]] text];
        NSString *_email = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientEmailFormField inSection:0]] text];
        SBRequest *request = [[SBSession defaultSession] addClientWithName:name phone:_phone email:_email
                                                                  callback:^(SBResponse *response)
        {
            [pendingRequests removeObject:response.requestGUID];
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
                        self.clientCreatedHandler(@{@"id" : response.result, @"name" : name, @"phone" : _phone, @"email" : _email});
                    }
                    else {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                });
            }
        }];
        [self.activityView startAnimating];
        [pendingRequests addObject:request.GUID];
        [[SBSession defaultSession] performReqeust:request];
    }
}

#pragma mark - textField validation

- (UIAlertView *)alertWithTitle:(NSString*)title message:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc ] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    return alert;
}

- (SBValidator *)notEmptyStringValidarot
{
    if (!_notEmptyStringValidarot) {
        _notEmptyStringValidarot = [SBValidator notEmptyStringValidator];
    }
    return _notEmptyStringValidarot;
}

- (SBValidator *)emailValidator
{
    if (!_emailValidator) {
        _emailValidator = [SBRegExpValidator emailAddressValidator];
    }
    return _emailValidator;
}

- (SBValidator *)phoneValidator
{
    if (!_phoneValidator) {
        _phoneValidator = [SBRegExpValidator phoneNumberValidator:YES];
    }
    return _phoneValidator;
}

- (BOOL)textFieldsValidation
{
    NSAssert(requiredFields != nil, @"information about required fields not loaded");
    NSAssert(![requiredFields isEqualToString:@""], @"information about required fields not loaded");
    NSString *emailString = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientEmailFormField inSection:0]] text];
    if ([requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmail]
        || [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmailAndPhone])
    {
        if (![self.notEmptyStringValidarot isValid:emailString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Email", @"") message:NSLS(@"Email address is required. Please enter valid email address.", @"")];
            [alert show];
            return NO;
        } else if(![self.emailValidator isValid:emailString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Email", @"") message:NSLS(@"Please enter valid email address.", @"")];
            [alert show];
            return NO;
        }
    } else if([self.notEmptyStringValidarot isValid:emailString] && ![self.emailValidator isValid:emailString]) {
        UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Email", @"") message:NSLS(@"Please enter valid email address.", @"")];
        [alert show];
        return NO;
    }
    
    NSString *phoneString = [[self textFieldForIndexPath:[NSIndexPath indexPathForRow:AddClientPhoneFormField inSection:0]] text];
    if ([requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValuePhone]
        || [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmailAndPhone])
    {
        if (![self.notEmptyStringValidarot isValid:phoneString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Phone", @"") message:NSLS(@"Phone number is required. Please enter valid phone number.", @"")];
            [alert show];
            return NO;
        } else if(![self.phoneValidator isValid:phoneString]) {
            UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Phone", @"") message:NSLS(@"Please enter valid phone number.", @"")];
            [alert show];
            return NO;
        }
    } else if([self.notEmptyStringValidarot isValid:phoneString] && ![self.phoneValidator isValid:phoneString]) {
        UIAlertView *alert = [self alertWithTitle:NSLS(@"Invalid Phone", @"") message:NSLS(@"Please enter valid phone number.", @"")];
        [alert show];
        return NO;
    }
    
    return YES;
}

- (BOOL)emailFieldIsRequired
{
    NSAssert(requiredFields != nil, @"information about required fields not loaded");
    NSAssert(![requiredFields isEqualToString:@""], @"information about required fields not loaded");
    return [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmail] || [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmailAndPhone];
}

- (BOOL)phoneFieldIsRequired
{
    NSAssert(requiredFields != nil, @"information about required fields not loaded");
    NSAssert(![requiredFields isEqualToString:@""], @"information about required fields not loaded");
    return [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValuePhone] || [requiredFields isEqualToString:kSBCompanyClientRequiredFieldsValueEmailAndPhone];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self emailFieldIsRequired] && [self phoneFieldIsRequired]) {
        return NSLS(@"Email address and phone number are mandatory fields.",@"");
    }
    else if ([self emailFieldIsRequired]) {
        return NSLS(@"Email address is mandatory field.", @"");
    }
    else if ([self phoneFieldIsRequired]) {
        return NSLS(@"Phone number is mandatory field.", @"");
    }
    return nil;
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (!textField.hasText && [self rowForTag:textField.tag] == AddClientPhoneFormField) {
        phone = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    else if (!textField.hasText && [self rowForTag:textField.tag] == AddClientEmailFormField) {
        email = [textField.text stringByReplacingCharactersInRange:range withString:string];
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
