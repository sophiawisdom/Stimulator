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
    float *_results; // length of blocks_wide*block_width + blocks_high*block_height + (stoplight_time + street_wide)*(blocks_high+blocks_wide), which should be maximum time
    int _min;
    int _max;
    long long _num_results;
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
        _results = calloc(sizeof(float), max_results);
    }
    return self;
}

- (int)size {
    return _max-_min;
}

- (void)acquireLock:(void (^)(float * _Nonnull, int, int, long long))lockBlock {
    dispatch_semaphore_wait(_results_lock, DISPATCH_TIME_FOREVER); // DISPATCH_TIME_FOREVER could lead
    // to problems, but for now it serves to simplify things because it can't fail.
    lockBlock(_results, _min, _max, _num_results);
    dispatch_semaphore_signal(_results_lock);
}

- (void)readValues:(void (^)(float * _Nonnull, int, int, long long))readBlock {
    // The insight here is that we don't need the most up-to-date or accurate value for _num_results,
    // and we don't need a lock on the underlying array, because it's append-only. Hopefully this should
    // meaningfully reduce contention
    __block float *copied_data = NULL;
    __block long long copied_results = 0;
    [self acquireLock:^(float * restrict _Nonnull results, int min, int max, long long num_results) {
        copied_results = num_results;
        copied_data = malloc(sizeof(float) * num_results);
        memcpy(copied_data, results, num_results*sizeof(float));
    }];
    readBlock(copied_data, _min, _max, copied_results);
}

- (long long)writeValues: (float *)values count:(int)count {
    __block long long cur_results = 0;
    // To think about: could we bring the memcpy outside of the lock?
    [self acquireLock:^(float * restrict _Nonnull results, int min, int max, long long num_results) {
        if (self -> _num_results + count > max_results) {
            // We already have enough results, no need for more.
            cur_results = -1;
        } else {
            memcpy(&results[self -> _num_results], values, sizeof(float) * count);
            self -> _num_results += count;
            cur_results = self -> _num_results;
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
