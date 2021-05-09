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
    Parameters *_params;
    Results *_results;
    int *_results_cache;
    int _cache_used;
    dispatch_semaphore_t _sem;
    
    /*
    long _last_flush;
    long _total_flush_time;
    long _num_flushes;
     */
}

static volatile int thread_num = 0;

- (instancetype)init
{
    if (self = [super init]) {
        printf("Starting simulatorthread\n");
        _results_cache = calloc(sizeof(float), cache_size);
        _cache_used = 0;
        _sem = dispatch_semaphore_create(1);
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(simulate) object:nil];
        _thread.name = [NSString stringWithFormat:@"SimulatorThread #%d", thread_num++];
        _thread.qualityOfService = NSQualityOfServiceBackground;
        _thread.stackSize = 0x19000; // small stack, we should only be going one or two layers deep of recursion.
        NSLog(@"Created thread, %@", _thread);
        
        /*
        _last_flush = -1;
        _total_flush_time = 0;
        _num_flushes = 0;
         */
    }
    return self;
}

- (void)newParams:(Parameters *)params andResults: (Results *)results { // main thread
    self.dirty = true;
    _params = params;
    _results = results;

    if (_thread_port) { // wake thread up if it's been suspended
        thread_resume(_thread_port);
    }
    if (![_thread isExecuting]) {
        [_thread start];
    }
}

- (void)pause {
    thread_suspend(_thread_port);
}

- (void)unpause {
    thread_resume(_thread_port);
}

- (void)dealloc
{
    free(_results_cache);
    mach_port_destroy(mach_task_self(), _thread_port);
}

- (void)flush_cache {
    long long total_written = [_results writeValues:self->_results_cache count:_cache_used];
    _cache_used = 0;
    /*
    long done_time = clock();
    if (_last_flush != -1) {
        _total_flush_time += done_time - _last_flush;
        _num_flushes++;
    }
    _last_flush = done_time;
     */
    if (total_written == -1 || total_written > max_results) {
        // If we've already written enough, put the thread in hibernation until the parameters change.
        // Another option instead of this would be to use something like [NSThread sleepForTimeInterval]
        // but I thought this would be lower-latency, and more accurately describes the intended semantics
        // ("sleep until something's changed").
        // printf("SUSPENDING THREAD %s. Did %ld flushes in %ld total time, average %g\n", _thread.name.UTF8String, _num_flushes, _total_flush_time, ( (double)_total_flush_time)/((double)_num_flushes));
        thread_suspend(_thread_port);
        // printf("UNSUSPENDED THREAD %s\n", _thread.name.UTF8String);
        // _last_flush = clock();
    }
}

- (void)simulate { // on _thread's thread
    _thread_port = mach_thread_self();
    while (1) {
        if (self.dirty) { // this line takes ~1/1000th of the overall time
            memset(_results_cache, 0, cache_size);
            _cache_used = 0;
            self.dirty = false;
        }

        struct diagnostics result = simulate(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, _params -> block_width, _params -> stoplight_time, _params -> street_width, _params -> policy);
        
        _results_cache[_cache_used++] = result.total_time * 8;
        if (_cache_used == cache_size) {
            [self flush_cache];
        }
    }
}

@end
