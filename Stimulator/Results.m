//
//  Results.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Results.h"
#import "SimulatorThread.h"
// #import <atomic.h>

@implementation Results {
    _Atomic int *_results; // length of blocks_wide*block_width + blocks_high*block_height + (stoplight_time + street_wide)*(blocks_high+blocks_wide), which should be maximum time
    int _min;
    int _max;
    _Atomic long long _num_results;
    int _max_writers;
    dispatch_semaphore_t _results_lock;
}

- (instancetype)initWithMin:(int)min Max:(int)max MaxWriters: (int)max_writers {
    self = [super init];
    if (self) {
        _min = min;
        _max = max;
        
        _results_lock = dispatch_semaphore_create(max_writers);
        _max_writers = max_writers;
        
        // Acquire lock to use these
        _num_results = 0;
        _results = calloc(sizeof(int), max-min);
    }
    return self;
}

- (int)size {
    return _max-_min;
}

- (void)readValues:(void (^)(int * _Nonnull, int, int))readBlock {
    // The insight here is that we don't need the most up-to-date or accurate value for _num_results,
    // and we don't need a lock on the underlying array, because it's append-only. Hopefully this should
    // meaningfully reduce contention
    for (int i = 0; i < _max_writers; i++) {
        dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER);
    }

    readBlock(_results, _min, _max);

    for (int i = 0; i < _max_writers; i++) {
        dispatch_semaphore_signal(_results_lock);
    }
}

- (long long)writeValues: (int *)values count:(int)count {
    dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER);
    long long sum = 0;
    for (int i = 0; i < count; i++) {
        _results[values[i]-_min] += 1;
        sum += values[i];
    }
    
    _num_results += sum; // hopefully reduce write traffic to _num_results...
    dispatch_semaphore_signal(_results_lock);
    return _num_results;
}

- (void)dealloc
{
    // could we somehow free all the waiters here?
    free(_results);
}

@end
