//
//  Results.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Results.h"
#import "SimulatorThread.h"

@implementation Results {
    _Atomic int *_results; // length of blocks_wide*block_width + blocks_high*block_height + (stoplight_time + street_wide)*(blocks_high+blocks_wide), which should be maximum time
    _Atomic long long _num_results;
    int _min;
    int _max;
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
        _results = calloc(sizeof(int), (max-min)*8);
    }
    return self;
}

- (int)size {
    return _max-_min;
}

- (void)readValues:(void (^)(_Atomic int * _Nonnull, int, int))readBlock {
    // The wait and signal in writeValues *should* be fast and mostly userside
    for (int i = 0; i < _max_writers; i++) {
        dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER);
    }

    readBlock(_results, _min, _max);

    for (int i = 0; i < _max_writers; i++) {
        dispatch_semaphore_signal(_results_lock);
    }
}

- (long long)writeValues: (int *)values count:(int)count {
    // The key insight here is that if we make the underlying array _Atomic, we can have as many writers
    // as we want, because every increment will be atomic. Mostly we won't even have too much contention,
    // because the writes will be spread out among a bunch of different values.
    // In practice, this is a ~100x reduction in time spent in this function vs one writer.

    dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER); // If this hits the kernel every time,
    // that would suck. Right now it isn't a big problem, but ideally we could do this userside.
    int adjusted_min = _min*8;
    for (int i = 0; i < count; i++) {
        _results[values[i]-adjusted_min] += 1;
    }
    
    _num_results += count; // hopefully reduce write traffic to _num_results...
    dispatch_semaphore_signal(_results_lock);
    return _num_results;
}

- (void)dealloc
{
    // could we somehow free all the waiters here? Perhaps destroy the semaphore? idk...
    free(_results);
}

@end
