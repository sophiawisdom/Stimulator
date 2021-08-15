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

@interface SimulatorThread()

@property (atomic) bool dirty;

@end

@implementation SimulatorThread {
    NSThread *_thread;
    mach_port_t _thread_port;
    ParametersObject *_params;
    SubprocessorResults *_results;
    int *_results_cache;
    int _cache_used;
    int _thread_num;
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
    }
    return self;
}

- (void)newParams:(ParametersObject *)params
{
    self.dirty = true;
    _params = params;

    if (_thread_port) { // wake thread up if it's been suspended
        thread_resume(_thread_port);
    }
    if (![_thread isExecuting]) {
        [_thread start];
    }
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
    struct thread_affinity_policy policy = {.affinity_tag=_thread_num};
    thread_policy_set(_thread_port, THREAD_AFFINITY_POLICY, &policy, THREAD_AFFINITY_POLICY_COUNT);
    while (1) {
        if (self.dirty) { // this line takes ~1/1000th of the overall time, not a priority to optimize.
            // memset(_results_cache, 0, cache_size);
            _cache_used = 0;
            self.dirty = false;
        }

        struct diagnostics result = simulate(_params -> _params);

        _results_cache[_cache_used++] = result.total_time * RESULTS_SPECIFICITY_MULTIPLIER;
        if (_cache_used == cache_size) {
            [self flush_cache];
        }
    }
}

- (NSString *)description
{
    return _thread.name;
}

@end
