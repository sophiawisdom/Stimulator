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
    unsigned long long _num_results;
    dispatch_semaphore_t _results_lock;
}

- (instancetype)initWithMin:(int)min Max:(int)max {
    self = [super init];
    if (self) {
        _min = min;
        _max = max;
        
        _results_lock = dispatch_semaphore_create(1);
        
        // Acquire lock to use these
        _num_results = 0;
        _results = calloc(sizeof(int), max-min);
    }
    return self;
}

- (int)size {
    return _max-_min;
}

- (void)acquireLock:(void (^)(int * _Nonnull, int, int))lockBlock {
    dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER); // DISPATCH_TIME_FOREVER could lead
    // to problems, but for now it serves to simplify things because it can't fail.
    lockBlock(_results, _min, _max);
    dispatch_semaphore_signal(_results_lock);
}

- (unsigned long long)writeValues: (int *)values count:(int)count {
    __block unsigned long long cur_results = 0;
    [self acquireLock:^(int * _Nonnull results, int min, int max) {
        self -> _num_results += count;
        cur_results = self -> _num_results;
        for (int i = 0; i < count; i++) {
            if (values[i] < min || values[i] > max) {
                printf("result is %d\n", values[i]);
            }
            results[values[i]-min] += 1;
        }
    }];
    return cur_results;
}

- (void)dealloc
{
    // could we somehow free all the waiters here?
    free(_results);
}

@end
