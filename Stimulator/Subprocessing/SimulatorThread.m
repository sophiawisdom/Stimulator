//
//  SimulatorThread.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "SimulatorThread.h"
#import "Results.h"

static const int cache_size = 500;

@implementation SimulatorThread {
    NSThread *_thread;
    mach_port_t _thread_port;
    ParametersObject *_params;
    SubprocessorResults *_results;
    int *_results_cache;
    int _cache_used;
    int _thread_num;
    
    _Atomic bool _dirty;
}

static volatile int thread_num = 0;

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
    }
    return self;
}

- (void)newParams:(ParametersObject *)params
{
    if (!_params) {
        _params = params;
        [_thread start];
        return;
    } else if (_thread_port) { // wake thread up if it's been suspended
        thread_resume(_thread_port);
    }

    self -> _dirty = true;
    while (self -> _dirty) {} // wait for simulation thread to see change, upon which time it will set _dirty to false
    _params = params;
    self -> _dirty = true; // we're done executing and the simulation thread can go
}

- (void)dealloc
{
    free(_results_cache);
    mach_port_deallocate(mach_task_self(), _thread_port); // mach_thread_self() allocates a port, unlike mach_task_self()
}

- (void)flush_cache {
    long long total_written = [_results writeValues:self->_results_cache count:_cache_used forParams:_params];
    _cache_used = 0;
    if (total_written == -1 || total_written > max_results) {
        // If we've already written enough, put the thread in hibernation until the parameters change.
        // Another option instead of this would be to use something like [NSThread sleepForTimeInterval]
        // but I thought this would be lower-latency, and more accurately describes the intended semantics
        // ("sleep until something's changed").
        thread_suspend(_thread_port);
    }
}

- (void)simulate { // on _thread's thread
    _thread_port = mach_thread_self(); /* leaks a thread port, but who cares lol */

    // Don't know if this is actually working. TODO: check if it works.
    struct thread_affinity_policy policy = {.affinity_tag=_thread_num};
    thread_policy_set(_thread_port, THREAD_AFFINITY_POLICY, &policy, THREAD_AFFINITY_POLICY_COUNT);
    int min = _params -> _params.min_time;
    int max = _params -> _params.max_time;
    while (1) {
        if (self -> _dirty) {
            self -> _dirty = false;
            while (!self -> _dirty) {}
            _cache_used = 0;
            min = _params -> _params.min_time;
            max = _params -> _params.max_time;
            self -> _dirty = false;
        }

        Parameters params = _params -> _params;
        double result = simulate(params);

        if (result < params.min_time || result > params.max_time) {
            printf("ERROR IN SIMULATE: %g, %d, %d\n", result, params.min_time, params.max_time);
            exit(1);
        }

        _results_cache[_cache_used++] = result * RESULTS_SPECIFICITY_MULTIPLIER;
        if (_cache_used >= cache_size) {
            [self flush_cache];
        }
    }
}

- (NSString *)description
{
    return _thread.name;
}

@end
