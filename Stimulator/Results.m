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

memory_object_size_t shared_results_size = max_array_size*sizeof(int)*RESULTS_SPECIFICITY_MULTIPLIER;
memory_object_size_t shared_command_size = sizeof(Command);

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
    int _max_writers;
    int _min;
    int _max;
    semaphore_t _command_sem;
    semaphore_t _results_sem;
    mach_port_t _child_task;
    pid_t _child_pid;
    Command _Atomic *_shared_command_buffer;
    int _Atomic *_shared_results;
}

#define MACH_CALL(kret) if (kret != 0) {\
printf("Mach call on line %d of file %s failed with error #%d \"%s\".\n", __LINE__, __FILE__, kret, mach_error_string(kret));\
exit(1);\
}

- (instancetype)initWithMaxWriters: (int)max_writers {
    self = [super init];
    if (self) {
        _max_writers = max_writers;
        int fds[2] = {0, 0}; // read, write fds
        pipe(fds);
        printf("About to fork...\n");
        _child_pid = fork();
        if (_child_pid == 0) {
            run_subprocess(fds[0], max_writers);
        }
        printf("child PID is %d\n", _child_pid);

        MACH_CALL(task_for_pid(mach_task_self(), _child_pid, &_child_task));
        MACH_CALL(semaphore_create(mach_task_self(), &_command_sem, SYNC_POLICY_FIFO, 0));
        MACH_CALL(semaphore_create(mach_task_self(), &_results_sem, SYNC_POLICY_FIFO, max_writers));
        
        int remote_command_sem = allocate_port(_child_task, _command_sem);
        int remote_results_sem = allocate_port(_child_task, _results_sem);
        printf("Writing sems: %d and %d\n", remote_command_sem, remote_results_sem);
        write(fds[1], &remote_command_sem, sizeof(remote_command_sem));
        write(fds[1], &remote_results_sem, sizeof(remote_results_sem));

        // This code is mostly taken from my "Tweaks" project. See https://github.com/sophiawisdom/tweaks/blob/master/injector_lib/TWEProcess.m for more discussion.
        // We're allocating two arrays that will be shared between the subprocess and the main process:
        // the command buffer and the shared results buffer. the command buffer is used to send information and commands, e.g. new code or new params, and is synchronized by the main semaphore.
        mach_vm_address_t remoteResultsAddress = 0;
        mach_vm_address_t remoteCommandAddress = 0;
        MACH_CALL(mach_vm_allocate(_child_task, &remoteResultsAddress, shared_results_size, true));
        MACH_CALL(mach_vm_allocate(_child_task, &remoteCommandAddress, shared_command_size, true));

        // mach_vm_map takes memory handles (ports), not raw addresses, so we need to get
        // a handle to the memory we just allocated.
        mach_port_t shared_results_handle = MACH_PORT_NULL;
        mach_port_t shared_command_handle = MACH_PORT_NULL;
        MACH_CALL(mach_make_memory_entry_64(_child_task,
                                  &shared_results_size,
                                  remoteResultsAddress, // Memory we're getting a handle for
                                  VM_PROT_READ | VM_PROT_WRITE,
                                  &shared_results_handle,
                                  MACH_PORT_NULL)); // parent entry - for submaps?
        MACH_CALL(mach_make_memory_entry_64(_child_task,
                                  &shared_command_size,
                                  remoteCommandAddress,
                                  VM_PROT_READ | VM_PROT_WRITE,
                                  &shared_command_handle,
                                  MACH_PORT_NULL));
        
        _shared_command_buffer = 0;
        // https://flylib.com/books/en/3.126.1.89/1/ has some documentation on this
        MACH_CALL(mach_vm_map(mach_task_self(),
                    (mach_vm_address_t*)&_shared_results, // Address in this address space
                    shared_results_size,
                    0xfff, // Alignment bits - make it page aligned
                    true, // Anywhere bit
                    shared_results_handle,
                    0,
                    false, // not sure what this means
                    VM_PROT_READ | VM_PROT_WRITE,
                    VM_PROT_READ | VM_PROT_WRITE,
                    VM_INHERIT_SHARE));
        _shared_command_buffer = 0;
        MACH_CALL(mach_vm_map(mach_task_self(),
                    (mach_vm_address_t*)&_shared_command_buffer,
                    shared_command_size,
                    0xfff,
                    true,
                    shared_command_handle,
                    0,
                    false,
                    VM_PROT_READ | VM_PROT_WRITE,
                    VM_PROT_READ | VM_PROT_WRITE,
                    VM_INHERIT_SHARE));
        
        write(fds[1], &remoteResultsAddress, sizeof(remoteResultsAddress));
        write(fds[1], &remoteCommandAddress, sizeof(remoteCommandAddress));
    }
    return self;
}

- (void)setParams:(ParametersObject *)newParams {
    _min = newParams -> _params.min_time;
    _max = newParams -> _params.max_time;
}

- (void)readValues:(void (^)(_Atomic int * _Nonnull, int, int))readBlock {
    // We acquire all the values on the semaphore to ensure there are no writers
    for (int i = 0; i < _max_writers; i++) {
        semaphore_wait(_results_sem);
    }

    readBlock(_shared_results, _min, _max);

    for (int i = 0; i < _max_writers; i++) {
        semaphore_signal(_results_sem);
    }
}

- (void)dealloc
{
    mach_vm_deallocate(_child_task, (mach_vm_address_t)_shared_command_buffer, shared_command_size);
    mach_vm_deallocate(_child_task, (mach_vm_address_t)_shared_results, shared_results_size);
    semaphore_destroy(_child_task, _command_sem);
    semaphore_destroy(_child_task, _results_sem);
    // To consider: does the next line accomplish the previous four? unclear... TODO: test this.
    kill(_child_pid, 9);
}

@end
