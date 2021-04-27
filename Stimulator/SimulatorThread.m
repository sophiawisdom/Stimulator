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
static const int max_results = 100 * 1000; // max number of simulations we should do before we stop.

@interface SimulatorThread()

@property (atomic) bool dirty;

@end

@implementation SimulatorThread {
    NSThread *_thread;
    mach_port_t _thread_port;
    Parameters *_params;
    Results *_results;
    int *_results_cache;
    int _cache_used;
    dispatch_semaphore_t _sem;
}

static int thread_num = 0;

- (instancetype)init
{
    if (self = [super init]) {
        printf("Starting simulatorthread\n");
        _results_cache = calloc(sizeof(int), cache_size);
        _cache_used = 0;
        _sem = dispatch_semaphore_create(1);
        _thread = [[NSThread alloc] initWithBlock:^{
            printf("Starting thread...\n");
            [self simulate];
        }];
        _thread.name = [NSString stringWithFormat:@"SimulatorThread #%d", thread_num++];
        _thread.qualityOfService = NSQualityOfServiceBackground;
        _thread.stackSize = 0x19000; // small stack
        NSLog(@"Created thread, %@", _thread);
    }
    return self;
}

- (void)newParams:(Parameters *)params andResults: (Results *)results { // main thread
    if (![_thread isExecuting]) {
        [_thread start];
    }
    self.dirty = true;
    _params = params;
    _results = results;

    if (_thread_port) { // thread is in hibernation, we have to wake it up.
        thread_resume(_thread_port);
    }
}

- (void)pause {
    self.dirty = true;
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
}

- (void)unpause {
    dispatch_semaphore_signal(_sem);
}

- (void)dealloc
{
    free(_results_cache);
}

- (void)simulate { // on _thread's thread
    while (1) {
        if (self.dirty) { // TODO: how long does atomically getting dirty take?
            dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_signal(_sem);
            memset(_results_cache, 0, cache_size);
            _cache_used = 0;
            self.dirty = false;
        }

        struct diagnostics result = simulate(_params -> _blocks_wide, _params -> _blocks_high, _params -> _block_height, _params -> _block_width, _params -> _stoplight_time, _params -> _street_width, _params -> _policy);
        
        _results_cache[_cache_used] = result.total_time;
        _cache_used += 1;
        if (_cache_used == cache_size) {
            // write back data. We have a results cache because getting a lock is expensive.
            unsigned long long total_written = [_results writeValues:self->_results_cache count:cache_size];
            _cache_used = 0;
            if (total_written > max_results) {
                // If we've already written enough, put the thread in hibernation until the parameters change.
                // Another option instead of this would be to use something like [NSThread sleepForTimeInterval]
                // but I thought this would be lower-latency, and more accurately describes the intended semantics
                // ("sleep until something's changed").
                printf("SUSPENDING THREAD\n");
                _thread_port = mach_thread_self();
                thread_suspend(mach_thread_self());
                _thread_port = MACH_PORT_NULL;
                printf("UNSUSPENDED\n");
            }
        }
    }
}

@end
