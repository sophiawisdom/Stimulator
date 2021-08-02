//
//  SubprocessorResults.m
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "SubprocessorResults.h"
#import "RealtimeGraphController.h"

@implementation SubprocessorResults {
    _Atomic int *_backing_arr; // array length is max_array_size
    _Atomic unsigned long long _num_results;
    semaphore_t _array_sem;
    
    int _min;
    int _max;
    int _max_writers;
    _Atomic unsigned long long _params; // just used as a pointer to make sure it's the same _params.
}

- (instancetype)initWithMaxWriters:(int)max_writers andBackingArray:(nonnull _Atomic(int) *)arr andArraySem:(semaphore_t)sem
{
    if (self = [super init]) {
        _max_writers = max_writers;
        _backing_arr = arr;
        _array_sem = sem;
        _num_results = 0;
    }
    return self;
}

- (void)setParams:(ParametersObject *)params {
    for (int i = 0; i < _max_writers; i++) {
        semaphore_wait(_array_sem);
    }
    
    _min = params -> _params.min_time;
    _max = params -> _params.max_time;
    _params = (unsigned long long)params;
    memset(_backing_arr, 0, max_array_size*RESULTS_SPECIFICITY_MULTIPLIER*sizeof(int));
    
    for (int i = 0; i < _max_writers; i++) {
        semaphore_signal(_array_sem);
    }
}

- (unsigned long long)writeValues:(nonnull int *)values count:(int)count forParams:(ParametersObject *)params {
    semaphore_wait(_array_sem);
    if ((unsigned long long)params != _params) { // the params object hasn't percolated through yet, so drop these on the floor.
        return 0;
    }

    int adjusted_min = _min*RESULTS_SPECIFICITY_MULTIPLIER;
    for (int i = 0; i < count; i++) {
        if (values[i] > (_max*RESULTS_SPECIFICITY_MULTIPLIER)) {
            printf("GOT INVALID VALUE %d > max %d\n", values[i]/RESULTS_SPECIFICITY_MULTIPLIER, _max);
            exit(1);
        }
        _backing_arr[values[i]-adjusted_min] += 1;
    }

    _num_results += count;

    semaphore_signal(_array_sem);
    return _num_results;
}

@end
