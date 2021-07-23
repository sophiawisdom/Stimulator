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
        NSLog(@"Created thread, %@", _thread);
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


// TODO: FIX THIS. this is almost certainly subtly wrong.
// One source of wrongness would be if we expected resumes and suspends to be balanced but 2 resumes
// happened before a suspend, which would effectively waste a resume.
// Another would be that [ newParams] overrides [ pause], which is sort of weird. Just generally,
// pause and unpause *should* be their own mechanism, which doesn't have potentially weird interactions
// with everything else.
- (void)pause {
    thread_suspend(_thread_port);
}

- (void)unpause {
    thread_resume(_thread_port);
}

- (void)dealloc
{
    free(_results_cache);
    mach_port_deallocate(mach_task_self(), _thread_port); // mach_thread_self() allocates a port, unlike mach_task_self()
}

- (void)flush_cache {
    long long total_written = [_results writeValues:self->_results_cache count:_cache_used];
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
    _thread_port = mach_thread_self();
    while (1) {
        if (self.dirty) { // this line takes ~1/1000th of the overall time
            memset(_results_cache, 0, cache_size);
            _cache_used = 0;
            self.dirty = false;
        }

        struct diagnostics result = simulate(_params);

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
