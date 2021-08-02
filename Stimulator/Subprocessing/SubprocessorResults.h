//
//  SubprocessorResults.h
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Results.h"
#import "ParametersObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubprocessorResults : NSObject

- (instancetype)initWithMaxWriters:(int)max_writers andBackingArray:(_Atomic int *)arr andArraySem:(semaphore_t)sem;

- (void)setParams:(ParametersObject *)params;

- (unsigned long long)writeValues:(nonnull int *)values count:(int)count forParams:(ParametersObject *)params;

@end

NS_ASSUME_NONNULL_END
