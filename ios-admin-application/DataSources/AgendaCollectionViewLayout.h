//
//  AgendaCollectionViewLayout.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kAgendaHeaderSupplementaryElementKind;
extern NSString * const kAgendaSubheaderSupplementaryElementKind;
extern NSString * const kAgendaNoDataSupplementaryElementKind;
extern NSString * const kAgendaNoConnectionSupplementaryElementKind;

@interface AgendaCollectionViewLayout : UICollectionViewLayout

@property (nonatomic) BOOL noConnection;

@end
