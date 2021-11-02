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
#include <sys/stat.h>
#include <x86intrin.h>
#import "simul_limited_string.h"

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
    NSString *_code_directory;
    NSString *_header;
}

#define MACH_CALL(kret) if (kret != 0) {\
printf("Mach call on line %d of file %s failed with error #%d \"%s\".\n", __LINE__, __FILE__, kret, mach_error_string(kret));\
exit(1);\
}

+ (instancetype)sharedResult {
    static dispatch_once_t onceToken;
    static Results *_result;
    dispatch_once(&onceToken, ^{
        _result = [[Results alloc] initWithNumThreads:8];
    });
    return _result;
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
        MACH_CALL(mach_vm_allocate(mach_task_self(), (mach_vm_address_t *)&_shared_results, shared_results_size+sizeof(shmem_semaphore), true));
        // And then mark it as VM_INHERIT_SHARE, which shares them with our subprocess when we fork.
        MACH_CALL(vm_inherit(mach_task_self(), (mach_vm_address_t)_shared_results, shared_results_size, VM_INHERIT_SHARE));

        _semaphore = (mach_vm_address_t)_shared_results + (mach_vm_address_t)shared_results_size;
        _semaphore -> need_read = false;
        _semaphore -> threads_writing = 0; // how many threads are writing
        

        _code_directory = [NSTemporaryDirectory() stringByAppendingString:@"mistulator/"];

        printf("About to fork...\n");
        _child_pid = fork();
        if (_child_pid == 0) {
            run_subprocess(process_to_subprocess[0], subprocess_to_process[1], num_threads, _shared_results, _semaphore, _code_directory);
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
        
        int resp = mkdir([_code_directory UTF8String], 0777);
        if (resp != 0 && errno != 17) { // errno 17 is file exists, so fine
            printf("GOT ERROR MAKING DIRECTORY: %d %s\n", errno, strerror(errno));
        }
        
        _header = [NSString stringWithUTF8String:simul_limited_string];

        // In practice this means that this object will not be deallocated until the process dies.
        // For the moment, that's fine.
        atexit_b(^{
            kill(self -> _child_pid, 9);
        });
    }
    return self;
}

- (Response)setParams:(ParametersObject *)newParams {
    /*
    if ([newParams isEqual:_params] && [function isEqualToString:_name]) {
        return NULL; // nothing to do
    }
     */
    if (![NSThread isMainThread]) {
        fprintf(stderr, "called on not main thread!!! %s\n", [[[NSThread callStackSymbols] componentsJoinedByString:@", "] UTF8String]);
        exit(1);
    }

    unsigned long function_length = [newParams -> _function lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (function_length > MAX_NAME_LEN) {
        printf("erroring, function_length is %lu\n", function_length);
        Response resp = {
            .response_type = Error
        };
        return resp;
    }
    _params = newParams;
    _max = newParams -> _params.max_time;
    _min = newParams -> _params.min_time;

    Command cmd = {
        .type_thing = SetParams,
        .params = {
            .params = newParams -> _params,
        }
    };
    const char * function = [newParams -> _function UTF8String];
    printf("function is %s. function length is %lu\n", function, function_length);
    memcpy(cmd.params.policy_name, function, function_length);
    printf("policy_name is %s\n", cmd.params.policy_name);
    write(_write_fd, &cmd, sizeof(cmd));
    printf("just wrote...\n");

    Response resp;
    read(_read_fd, &resp, sizeof(Response));
    printf("just read\n");
    return resp;
}

- (bool)addPolicy:(NSString *)policy withCode:(NSString *)code {
    if ([policy containsString:@"/"] || [policy lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > MAX_NAME_LEN) {
        return false;
    }
    
    NSLog(@"writing code %@", code);
    
    NSString *dest = [_code_directory stringByAppendingFormat:@"%@.c", policy];
    NSError *err;
    NSString *appended_string = [[_header stringByAppendingString:code] stringByReplacingOccurrencesOfString:@";" withString:@";\n"];
    [appended_string writeToFile:dest atomically:false encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"got err while writing data: %@ to dest %@", err, dest);
    }
    return true;
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
