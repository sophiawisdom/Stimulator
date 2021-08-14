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
    
    int _min;
    int _max;
    int _num_threads;
    _Atomic unsigned long long _params; // just used as a pointer to make sure it's the same _params.
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
    printf("SUBPROCESS: SETPARAMS CALLED\n");
    _semaphore -> need_read = true; // THIS IS EXTREMELY FRAGILE AND BAD. I THINK IT IS FINE FOR NOW
    // BECAUSE THE MAIN THREAD OF THE UI PROCESS SHOULD BE WAITING FOR THIS TO COMPLETE

    _min = params -> _params.min_time;
    _max = params -> _params.max_time;
    _params = (unsigned long long)params;
    memset(_backing_arr, 0, max_array_size*RESULTS_SPECIFICITY_MULTIPLIER*sizeof(int));

    _semaphore -> need_read = false;
}

- (unsigned long long)writeValues:(nonnull int *)values count:(int)count forParams:(ParametersObject *)params {
    if ((unsigned long long)params != _params) { // the params object hasn't percolated through yet, so drop these on the floor.
        return 0;
    }

    while (_semaphore -> need_read) {}
    _semaphore -> threads_writing++;
    
    if ((random()&63) == 0) {
        int sum = 0;
        for (int i = 0; i < count; i++) {
            sum += values[i];
        }
        // printf("SUBPROCESS: WRITING %d VALUES (sum %d) TO ARRAY\n", count, sum);
    }

    int adjusted_min = _min*RESULTS_SPECIFICITY_MULTIPLIER;
    int adjusted_max = _max*RESULTS_SPECIFICITY_MULTIPLIER;
    for (int i = 0; i < count; i++) {
        if (values[i] > adjusted_max) {
            printf("GOT INVALID VALUE %d > max %d\n", values[i]/RESULTS_SPECIFICITY_MULTIPLIER, _max);
            exit(1);
        }
        _backing_arr[values[i]-adjusted_min]++;
    }

    _num_results += count;
    
    _semaphore -> threads_writing--;

    return _num_results;
}

@end
