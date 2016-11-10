//
//  TermsAndConditionsController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 08.11.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "TermsAndConditionsController.h"

@implementation TermsAndConditionsController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.activityIndicator startAnimating];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://simplybook.me/en/terms-and-conditions"]];
    [self.webView loadRequest:request];
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
}

@end
