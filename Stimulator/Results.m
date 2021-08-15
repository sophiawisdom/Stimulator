//
//  Results.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Results.h"
#import "SimulatorThread.h"
#import "Subprocessor.h"
#import "RealtimeGraphController.h"
#include <sys/time.h>
#include <x86intrin.h>

memory_object_size_t shared_results_size = max_array_size*sizeof(int)*RESULTS_SPECIFICITY_MULTIPLIER;

semaphore_t allocate_port(task_t child_task, semaphore_t sem) {
    int port_retval = 1;
    semaphore_t sem_port = 0;
    while (port_retval != 0) {
        sem_port = (int)random();
        port_retval = mach_port_insert_right(child_task, sem_port, sem, MACH_MSG_TYPE_COPY_SEND);
    }
    return sem_port;
}

@implementation Results {
    int _num_threads;
    int _min;
    int _max;

    int _write_fd;
    int _read_fd;
    semaphore_t _results_sem;
    mach_port_t _child_task;
    pid_t _child_pid;
    int _Atomic *_shared_results;
    shmem_semaphore *_semaphore;
    
    ParametersObject *_params;
    NSString *_name;
}

#define MACH_CALL(kret) if (kret != 0) {\
printf("Mach call on line %d of file %s failed with error #%d \"%s\".\n", __LINE__, __FILE__, kret, mach_error_string(kret));\
exit(1);\
}

- (instancetype)initWithNumThreads: (int)num_threads {
    self = [super init];
    if (self) {
        _num_threads = num_threads;
        int process_to_subprocess[2] = {0, 0}; // read, write
        int subprocess_to_process[2] = {0, 0}; // read, write
        pipe(process_to_subprocess);
        pipe(subprocess_to_process);
        
        // Allocate a new block of memory
        MACH_CALL(mach_vm_allocate(mach_task_self(), (mach_vm_address_t *)&_shared_results, shared_results_size+0x1000, true));
        // And then mark it as VM_INHERIT_SHARE, which shares them with our subprocess when we fork.
        MACH_CALL(vm_inherit(mach_task_self(), (mach_vm_address_t)_shared_results, shared_results_size, VM_INHERIT_SHARE));

        _semaphore = (mach_vm_address_t)_shared_results + (mach_vm_address_t)shared_results_size;
        _semaphore -> need_read = false;
        _semaphore -> threads_writing = 0; // how many threads are writing

        printf("About to fork...\n");
        _child_pid = fork();
        if (_child_pid == 0) {
            run_subprocess(process_to_subprocess[0], subprocess_to_process[1], num_threads, _shared_results, _semaphore);
        }
        _write_fd = process_to_subprocess[1];
        _read_fd = subprocess_to_process[0];
        printf("child PID is %d\n", _child_pid);

        MACH_CALL(task_for_pid(mach_task_self(), _child_pid, &_child_task));
        MACH_CALL(semaphore_create(mach_task_self(), &_results_sem, SYNC_POLICY_FIFO, 0));
        for (int i = 0; i < _num_threads; i++) {
            semaphore_signal(_results_sem);
        }

        int remote_results_sem = allocate_port(_child_task, _results_sem);
        printf("allocated port is %d\n", remote_results_sem);
        write(_write_fd, &remote_results_sem, sizeof(remote_results_sem));
    }
    return self;
}

- (Response)setParams:(ParametersObject *)newParams function:(nonnull NSString *)function {
    /*
    if ([newParams isEqual:_params] && [function isEqualToString:_name]) {
        return NULL; // nothing to do
    }
     */
    unsigned long function_length = [function lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (function_length > MAX_NAME_LEN) {
        Response resp = {
            .response_type = Error
        };
        return resp;
    }
    _params = newParams;
    _name = function;
    _max = newParams -> _params.max_time;
    _min = newParams -> _params.min_time;

    Command cmd = {
        .type_thing = SetParams,
        .params = {
            .params = newParams -> _params,
        }
    };
    memcpy(cmd.params.policy_name, [function UTF8String], function_length);
    write(_write_fd, &cmd, sizeof(cmd));
    
    Response resp;
    read(_read_fd, &resp, sizeof(Response));
    return resp;
}

- (void)readValues:(void (^)(_Atomic int * _Nonnull, int, int))readBlock {
    if (![NSThread isMainThread] || _semaphore -> need_read) {
        fprintf(stderr, "READVALUES CAN ONLY BE ACCESSED ON MAIN THREAD\n");
        return;
    }
    _semaphore -> need_read = true;
    while (_semaphore -> threads_writing) {} // Spin until no more threads are waiting. On average, this is <5µs. In extreme configurations, this could be a problem.

    readBlock(_shared_results, _min, _max);

    _semaphore -> need_read = false;
}

- (void)dealloc
{
    mach_vm_deallocate(_child_task, (mach_vm_address_t)_shared_results, shared_results_size);
    semaphore_destroy(_child_task, _results_sem);
    // To consider: does the next line accomplish the previous two? unclear... TODO: test this.
    kill(_child_pid, 9);
}

@end
