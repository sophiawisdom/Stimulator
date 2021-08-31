//
//  speed_test.c
//  Stimulator
//
//  Created by Sophia Wisdom on 8/26/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#include <stdio.h>
#include "Simul.h"
#import "ParametersObject.h"
#import "Subprocessing/SimulatorThread.h"

#define iterations (10000000)

int main() {
    Parameters params = [ParametersObject defaultParams] -> _params;
    srandomdev();
    
    global_rand = InitFastRand();
    
    printf("beginning simulation... ch-ch-ch change please\n");
    
    struct thread_affinity_policy policy = {.affinity_tag=0};
    thread_policy_set(mach_thread_self(), THREAD_AFFINITY_POLICY, &policy, THREAD_AFFINITY_POLICY_COUNT);
    
    // warmup
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }

    long begin = clock();
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    params.policy = faster_policy;
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    params.policy = avoid_waiting_policy;
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    params.blocks_high = 100;
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    params.stoplight_time = 50;
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    params.block_width = 30;
    for (int i = 0; i < iterations; i++) {
        simulate(params);
    }
    long end = clock();
    printf("Took %ldµs in total or %gµs/iteration\n", (end-begin), (end-begin)/(6.0*iterations));
    return 0;
}
