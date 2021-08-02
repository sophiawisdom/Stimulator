//
//  Results.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParametersObject.h"

NS_ASSUME_NONNULL_BEGIN

#define RESULTS_SPECIFICITY_MULTIPLIER (8)

@interface Results : NSObject

- (instancetype)initWithMaxWriters: (int)max_writers;

// Used for determining speed of simulate() function
#ifdef SPEED_CHECK
// @property (nonatomic, readonly) long long num_results; // approximate number of results, no guarantee on freshness
@property (nonatomic, readonly) long long beginning; // unix time µs at which this was created
#endif

- (void)readValues:(void (^)(_Atomic int * _Nonnull, int, int))readBlock;

- (void)setParams:(ParametersObject *)newParams;

@end

NS_ASSUME_NONNULL_END
