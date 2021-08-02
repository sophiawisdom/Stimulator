//
//  Subprocessor.h
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#include <sys/types.h>
#include <mach/mach_types.h>

enum CommandType {
    SetParams = 0, // Send new parameters
    Shutdown = 1, // Shut down subprocess
    SendCode = 2, // Send code to be compiled
};

typedef struct command {
    int type_thing;
    union {
        Parameters params; // in case of SetParams
        char code[4096]; // in case of SendCode
    };
} Command;

__attribute__((noreturn)) int run_subprocess(int read_fd, int num_threads);
