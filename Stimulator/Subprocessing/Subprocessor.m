//
//  Subprocessor.m
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#import "SimulatorThread.h"
#import "Subprocessor.h"
#import "SubprocessorResults.h"

void addSymbol(NSString *policy_name, NSString *code_dir) {
    NSString *input_filename = [NSString stringWithFormat:@"%@%@.c", code_dir, policy_name];
    NSString *output_filename = [NSString stringWithFormat:@"%@%@.dylib", code_dir, policy_name];

    NSPipe *pipe = [NSPipe pipe];

    NSTask *task = [[NSTask alloc] init];
    NSLog(@"%@", [NSString stringWithContentsOfFile:input_filename encoding:NSUTF8StringEncoding error:nil]);
    task.launchPath = @"/usr/bin/clang";
    task.arguments = @[input_filename, @"-Ofast", @"-ffast-math", @"-march=native", @"-shared", @"-o", output_filename];
    NSLog(@"arguments are %@", task.arguments);
    task.standardOutput = pipe;
    task.standardError = pipe;
    [task launch];
    [task waitUntilExit];

    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"termination status is %d, clang output is %@\n", task.terminationStatus, str);

    void *handle = dlopen([output_filename UTF8String], RTLD_GLOBAL);
    printf("handle is %p\n", handle);
    printf("error: %s\n", dlerror());
}

int run_subprocess(int read_fd, int write_fd, int num_threads, _Atomic int *shared_results, shmem_semaphore *semaphore_count, NSString *code_dir) {
    printf("Trying to read from read_fd (%d)\n", read_fd);

    semaphore_t array_sem;
    read(read_fd, &array_sem, sizeof(semaphore_t));
    printf("array_sem is %d\n", array_sem);

    printf("SUBPROCESS: Read shared_results: %p\n", shared_results);

    SubprocessorResults *results = [[SubprocessorResults alloc] initWithNumThreads:num_threads andBackingArray:shared_results andManualSem:semaphore_count];

    NSMutableArray<SimulatorThread *> *threadpool = [[NSMutableArray alloc] initWithCapacity:num_threads];
    for (int i = 0; i < num_threads; i++) {
        [threadpool addObject:[[SimulatorThread alloc] initWithResults:results]];
    }
    
    NSMutableSet<NSString *> *symbols = [NSMutableSet setWithCapacity:100];
    for (int i = 0; i < 4; i++) {
        [symbols addObject:[NSString stringWithUTF8String:policies[i]]];
    }
    NSLog(@"symbols are %@", symbols);

    Response resp;
    Command *read_buffer = calloc(1, MAX_BUFFER_SIZE);
    while (1) {
        ssize_t bytes_read = read(read_fd, read_buffer, MAX_BUFFER_SIZE);
        if (bytes_read == 0) { // reached EOF, i.e. the parent process has died.
            exit(0);
        } else if (bytes_read == -1) {
            strerror(errno);
            exit(1);
        }

        resp.response_type = OK;

        if (read_buffer -> type_thing == SetParams) {
            Parameters params = read_buffer -> params.params;
            NSString *policy_name = [NSString stringWithUTF8String:read_buffer -> params.policy_name];
            if (![symbols containsObject:policy_name]) {
                addSymbol(policy_name, code_dir);
            }
            PolicyFunc policy_func = dlsym(RTLD_DEFAULT, read_buffer -> params.policy_name);
            if (policy_func == NULL) {
                printf("SUBPROCESS: Encountered error looking for symbol \"%s\": %s\n", read_buffer -> params.policy_name, dlerror());
                resp.response_type = Error;
                sprintf(resp.error, "Could not find function named %s: %s\n", read_buffer -> params.policy_name, dlerror());
            } else {
                ParametersObject *newParams = [[ParametersObject alloc] initWithBlocksWide:params.blocks_wide blocksHigh:params.blocks_high blockHeight:params.block_height blockWidth:params.block_width stoplightTime:params.stoplight_time streetWidth:params.street_width policy:policy_func policyName:nil];
                [results setParams:newParams];
                [threadpool enumerateObjectsUsingBlock:^(SimulatorThread * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
                    [thread newParams:newParams];
                }];
            }
        } else if (read_buffer -> type_thing == Shutdown) {
            exit(1);
        } else if (read_buffer -> type_thing == SendCode) {
            printf("SUBPROCESS: we were asked to SendCode\n");
        } else {
            printf("Got garbage response\n");
        }
        
        write(write_fd, &resp, sizeof(resp));
    }
}
