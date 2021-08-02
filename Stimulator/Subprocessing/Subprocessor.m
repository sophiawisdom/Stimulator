//
//  Subprocessor.m
//  Stimulator
//
//  Created by Sophia Wisdom on 8/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimulatorThread.h"
#import "Subprocessor.h"
#import "SubprocessorResults.h"

int run_subprocess(int read_fd, int num_threads) {
    
    printf("Trying to read from read_fd (%d)\n", read_fd);
    
    semaphore_t command_sem, results_sem;
    read(read_fd, &command_sem, sizeof(semaphore_t));
    read(read_fd, &results_sem, sizeof(semaphore_t));

    Command _Atomic *shared_command_buffer;
    read(read_fd, &shared_command_buffer, sizeof(shared_command_buffer));
    printf("SUBPROCESS: Read shared_command_buffer: %p\n",shared_command_buffer);
    int _Atomic *shared_results;
    read(read_fd, &shared_results, sizeof(shared_results));
    printf("SUBPROCESS: Read shared_results: %p\n", shared_results);
    
    usleep(1000*10); // 10ms
    
    SubprocessorResults *results = [[SubprocessorResults alloc] initWithMaxWriters:num_threads andBackingArray:shared_results andArraySem:results_sem];
    
    NSMutableArray<SimulatorThread *> *threadpool = [[NSMutableArray alloc] initWithCapacity:num_threads];
    for (int i = 0; i < num_threads; i++) {
        [threadpool addObject:[[SimulatorThread alloc] initWithResults:results]];
    }

    while (1) {
        semaphore_wait(command_sem);
        Command newCommand;
        memcpy(shared_command_buffer, &newCommand, sizeof(Command));
        
        if (newCommand.type_thing == SetParams) {
            ParametersObject *newParams = [[ParametersObject alloc] initWithBlocksWide:newCommand.params.blocks_wide blocksHigh:newCommand.params.blocks_high blockHeight:newCommand.params.block_height blockWidth:newCommand.params.block_width stoplightTime:newCommand.params.stoplight_time streetWidth:newCommand.params.street_width policy:newCommand.params.policy];
            [threadpool enumerateObjectsUsingBlock:^(SimulatorThread * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
                [thread newParams:newParams];
            }];
        } else if (newCommand.type_thing == Shutdown) {
            
        } else if (newCommand.type_thing == SendCode) {
            printf("SUBPROCESS: we were asked to SendCode, but this hasn't been implemented yet. doing nothing.\n");
        }
    }
}
