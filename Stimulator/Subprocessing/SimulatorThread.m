//
//  SimulatorThread.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "SimulatorThread.h"
#include "signal.h"

static const int cache_size = 5;

@implementation SimulatorThread {
    NSThread *_thread;
    mach_port_t _thread_port;
    ParametersObject *_params;
    SubprocessorResults *_results;
    int *_results_cache;
    int _cache_used;
    int _thread_num;
    
    _Atomic bool _dirty;
    _Atomic bool _suspended;
    _Atomic bool _reading;
}

static volatile _Atomic int thread_num = 0;

- (instancetype)initWithResults: (SubprocessorResults *)results
{
    if (self = [super init]) {
        _results_cache = calloc(sizeof(int), cache_size);
        _cache_used = 0;
        _results = results;
        _thread_num = thread_num++;
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(simulate) object:nil];
        _thread.name = [NSString stringWithFormat:@"SimulatorThread #%d", _thread_num];
        _thread.qualityOfService = NSQualityOfServiceBackground;
        _dirty = false;
        _suspended = false;
    }
    return self;
}

- (void)newParams:(ParametersObject *)params
{
    if (!_params) {
        _params = params;
        [_thread start];
        return;
    } else if (_thread_port && _suspended) { // wake thread up if it's been suspended
        _suspended = false;
        thread_resume(_thread_port);
    }
    
    while (_reading) {}
    _params = params;
    self -> _dirty = true;
}

- (void)dealloc
{
    free(_results_cache);
    mach_port_deallocate(mach_task_self(), _thread_port); // mach_thread_self() allocates a port, unlike mach_task_self()
}

- (void)writeForParams:(ParametersObject *)params {
    long long total_written = [_results writeValues:self->_results_cache count:_cache_used forParams:params];

    _cache_used = 0;
    if (total_written == -1 || total_written > max_results) {
        // If we've already written enough, put the thread in hibernation until the parameters change.
        // Another option instead of this would be to use something like [NSThread sleepForTimeInterval]
        // but I thought this would be lower-latency, and more accurately describes the intended semantics
        // ("sleep until something's changed").
        _suspended = true;
        thread_suspend(_thread_port);
    }
}

- (void)simulate { // on _thread's thread
    _thread_port = mach_thread_self();

    // Don't know if this is actually working. TODO: check if it works.
    struct thread_affinity_policy policy = {.affinity_tag=_thread_num};
    thread_policy_set(_thread_port, THREAD_AFFINITY_POLICY, &policy, THREAD_AFFINITY_POLICY_COUNT);
    int min = _params -> _params.min_time;
    int max = _params -> _params.max_time;
    Parameters params = _params -> _params;
    ParametersObject *cur_params = _params;

    while (1) {
        if (self -> _dirty) {
            self -> _reading = true;
            self -> _dirty = false;
            _cache_used = 0;
            min = _params -> _params.min_time;
            max = _params -> _params.max_time;
            params = _params -> _params;
            cur_params = _params;
            self -> _reading = false;
        }

        double result = simulate(params);

        if (result < params.min_time || result > params.max_time) {
            printf("ERROR IN SIMULATE: %g, %d, %d\n", result, params.min_time, params.max_time);
            exit(1);
        }

        _results_cache[_cache_used++] = result * RESULTS_SPECIFICITY_MULTIPLIER;
        if (_cache_used == cache_size && !self -> _dirty) {
            [self writeForParams:cur_params];
        }
    }
}

- (NSString *)description
{
    return _thread.name;
}

@end
