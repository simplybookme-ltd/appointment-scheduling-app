//
//  TermsAndConditionsController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 08.11.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TermsAndConditionsController : UIViewController <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
