//
//  SimulatorThread.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubprocessorResults.h"
#import "ParametersObject.h"

NS_ASSUME_NONNULL_BEGIN

static const long max_results = 1000*1000; // max number of simulations we should do before we stop.

@interface SimulatorThread : NSObject

- (instancetype)initWithResults: (SubprocessorResults *)results;

- (void)newParams:(ParametersObject *)params;

@end

NS_ASSUME_NONNULL_END
