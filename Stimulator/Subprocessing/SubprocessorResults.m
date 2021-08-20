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
    shmem_semaphore *_semaphore;
    
    _Atomic bool _dirty;
    
    _Atomic int _min;
    _Atomic int _max;
    _Atomic unsigned long long _params; // just used as a pointer to make sure it's the same _params.
    int _num_threads;
}

- (instancetype)initWithNumThreads:(int)num_threads andBackingArray:(nonnull _Atomic(int) *)arr andManualSem:(shmem_semaphore *)semaphore
{
    if (self = [super init]) {
        _num_threads = num_threads;
        _backing_arr = arr;
        _num_results = 0;
        _semaphore = semaphore;
    }
    return self;
}

- (void)setParams:(ParametersObject *)params {
    _dirty = true;
    while (_semaphore -> threads_writing) {}
    
    _params = (unsigned long long)params;
    _min = params -> _params.min_time;
    _max = params -> _params.max_time;
    memset(_backing_arr, 0, max_array_size*RESULTS_SPECIFICITY_MULTIPLIER*sizeof(int));

    _dirty = false;
}

- (unsigned long long)writeValues:(nonnull int *)values count:(int)count forParams:(ParametersObject *)params {
    while (_semaphore -> need_read || _dirty) {} // spin if reading. we do this here and not below because
    // setParams sets need_read and changes the params.
    
    // Is it possible this checks for _dirty, it's false, _dirty is set on setParams, it checks threads_writing, it's 0, then threads_writing is incremented?
    _semaphore -> threads_writing++; // indicate we are writing (so nothing reads)
    if (params != _params) { // the params object hasn't percolated through yet, so drop these on the floor. TODO: should we do more in-depth comparisons?
        _semaphore -> threads_writing--;
        return 0;
    }

    int adjusted_min = _min*RESULTS_SPECIFICITY_MULTIPLIER;
    int adjusted_max = _max*RESULTS_SPECIFICITY_MULTIPLIER;
    for (int i = 0; i < count; i++) {
        int value = values[i];
        if (value > adjusted_max || value < adjusted_min) {
            _num_results -= 1; // just drop the value on the floor. so what if it's incorrect. get off my back, sjws.
            /*
            printf("GOT INVALID VALUE %d > max %d\n", values[i]/RESULTS_SPECIFICITY_MULTIPLIER, _max);
            printf("_params is %p, params is %p\n", _params, params);
            exit(1);
             */
        }
        _backing_arr[value-adjusted_min]++;
    }
 
    _num_results += count;

    _semaphore -> threads_writing--; // indicate we are no longer writing
    return _num_results;
}

@end
