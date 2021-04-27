//
//  SimulatorThread.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "SimulatorThread.h"
#import "Results.h"

int cache_len = 100;

@interface SimulatorThread()

@property (atomic) bool dirty;

@end

@implementation SimulatorThread {
    NSThread *_thread;
    Parameters *_params;
    Results *_results;
    int *_results_cache;
    int _cache_used;
    dispatch_semaphore_t _sem;
    int _total_written;
}

static int thread_num = 0;

- (instancetype)init
{
    if (self = [super init]) {
        printf("Starting simulatorthread\n");
        _results_cache = calloc(sizeof(int), cache_len);
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
    // NSLog(@"Writing new params: %@\n", _params);
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
        if (self.dirty) { // TODO: how long does this take?
            dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_signal(_sem);
            memset(_results_cache, 0, cache_len);
            _cache_used = 0;
            self.dirty = false;
        }

        struct diagnostics result = simulate(_params -> _blocks_wide, _params -> _blocks_high, _params -> _block_height, _params -> _block_width, _params -> _stoplight_time, _params -> _street_width, _params -> _policy);
        
        _results_cache[_cache_used] = result.total_time;
        _cache_used += 1;
        if (_cache_used == cache_len) {
            // write back data. We have a results cache because getting a lock is expensive.
            // Runs synchronously... should it be async?? expensive to launch another thread etc. etc.
            [_results writeValues:self->_results_cache count:cache_len];
            _cache_used = 0;
            _total_written += cache_len;
        }
    }
}

@end
