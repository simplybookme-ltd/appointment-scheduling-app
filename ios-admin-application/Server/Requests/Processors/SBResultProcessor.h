//
//  SBResultProcessor.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBResultProcessor : NSObject

@property (nonatomic, strong, nullable) id result;
@property (nonatomic, strong, nullable) NSError *error;

- (BOOL)process:(nonnull id)result;
- (nonnull SBResultProcessor *)addResultProcessorToChain:(nonnull SBResultProcessor *)processor;

@end

@interface SBClassCheckProcessor : SBResultProcessor

@property (nonatomic, nonnull) Class expectedClass;

+ (nullable instancetype)classCheckProcessorWithExpectedClass:(nonnull Class)expectedClass;

@end

/**
 * Prints response result to console.
 * Allways valid.
 */
@interface SBDebugProcessor : SBResultProcessor

+ (nullable instancetype)debugProcessor;

@end

/**
 * Check if result object is instance of NSDictionary class and remove all NSNull objects from
 * dictionary values.
 */
@interface SBSafeDictionaryProcessor : SBClassCheckProcessor

+ (nullable instancetype)safeDictionaryProcessor;

@end

/**
 * Check if result object is an instance of NSNumber class or a NSString with a numeric value.
 */
@interface SBNumberProcessor : SBResultProcessor

@end