//
//  Subprocessor.h
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#include <sys/types.h>
#include <mach/mach_types.h>

// One day make a better method for this that involves sending a dynamic length string...
#define MAX_CODE_LEN 4096
#define MAX_NAME_LEN 128

typedef enum CommandType {
    SetParams = 0, // Send new parameters
    Shutdown = 1, // Shut down subprocess
    SendCode = 2, // Send code to be compiled. The response will be a function identifier you can use with SetParams in the future. TODO: should this automatically toggle the new function
} CommandType;

typedef enum FunctionType {
    PolicyFunction = 0,
    StoplightFunction = 1
} FunctionType;

// This is bad, ideally it wouldn't be a union and you could chose different types... fine for now though.
typedef struct command {
    CommandType type_thing;
    union {
        struct SetParams { // for SetParams
            Parameters params;
            char policy_name[MAX_NAME_LEN];
        } params;
        struct SendCodeParams {
            char code[MAX_CODE_LEN]; // for sending code with SendCode
            
        } send_code_params;
    };
} Command;

typedef enum ResponseType {
    OK = 0,
    SendCodeResponse = 1,
    Error = 2,
} ResponseType;

typedef struct response {
    ResponseType response_type;
    union {
        char error[1024]; // in case of Error
        char function_identifier[MAX_NAME_LEN]; // function identifier in response to SendCodeResponse
    };
} Response;

typedef struct shmem_semaphore {
    _Atomic bool need_read;
    _Atomic int threads_writing;
} shmem_semaphore;

#define MAX_BUFFER_SIZE (sizeof(Command) > sizeof(Response) ? sizeof(Command) : sizeof(Response))

int run_subprocess(int read_fd, int write_fd, int num_threads, _Atomic int *shared_results, shmem_semaphore *semaphore_count);
