//
//  LSPerformer.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "LSPerformer.h"

@implementation LSPerformer

- (NSString *)id
{
    return self.performerID;
}

- (id)primarySortingField
{
    return self.position;
}

- (id)secondarySortingField
{
    return self.name;
}


@end
