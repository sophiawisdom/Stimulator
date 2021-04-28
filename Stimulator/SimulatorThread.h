//
//  SimulatorThread.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Results.h"
#import "Parameters.h"

NS_ASSUME_NONNULL_BEGIN

static const int max_results = 100000 * 1000; // max number of simulations we should do before we stop.

@interface SimulatorThread : NSObject

- (instancetype)init;

- (void)newParams:(Parameters *)params andResults: (Results *)results;

@end

NS_ASSUME_NONNULL_END
