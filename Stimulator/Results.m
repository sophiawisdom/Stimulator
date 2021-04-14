//
//  Results.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Results.h"

@implementation Results {
    int *_results; // length of blocks_wide*block_width + blocks_high*block_height + (stoplight_time + street_wide)*(blocks_high+blocks_wide), which should be maximum time
    int _min;
    int _max;
    dispatch_semaphore_t _results_lock;
}

- (instancetype)initWithMin:(int)min Max:(int)max {
    self = [super init];
    if (self) {
        _results = calloc(sizeof(int), max-min);
        _min = min;
        _max = max;
        _results_lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (int)size {
    return _max-_min;
}

- (void)acquireLock:(void (^)(int * _Nonnull, int, int))lockBlock {
    dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER);
    lockBlock(_results, _min, _max);
    dispatch_semaphore_signal(_results_lock);
}

- (void)dealloc
{
    // could we somehow free all the waiters here?
    free(_results);
}

@end
