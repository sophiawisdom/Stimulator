#include "stdbool.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "Simul.h"

#undef DEBUG

int get_stoplight_time(struct simul *simulation, int x, int y) {
    // Instead of pre-calculating the stoplight times, we load the dynamically
    int index = x * simulation -> blocks_high + y;
    if (simulation -> times[index] == 0) {
        double value = (double)random()/(double)(RAND_MAX/simulation->stoplight_time);
        simulation -> times[index] = value;
        simulation -> diag.num_randoms += 1;
    }
    return simulation -> times[index];
}

int stoplight_wait(struct simul *simulation, PolicyResult direction) {
    int effective_x = simulation -> current_x - !simulation->x_right + 1;
    int effective_y = simulation -> current_y - !simulation->y_top + 1;
#ifdef DEBUG
    printf("effective_x is %d, effective_y is %d\n", effective_x, effective_y);
#endif
    int stoplight_time = get_stoplight_time(simulation, effective_x, effective_y);

    int current_time = simulation -> cur_t % (simulation -> stoplight_time * 3);
    int cycle_time = simulation -> stoplight_time * 3;
    if (direction == Top) {
        if (current_time <= stoplight_time) {
            return 0;
        } else {
            return cycle_time - current_time;
        }
    } else if (direction == Right) {
        if (current_time <= stoplight_time) {
            return stoplight_time - current_time;
        } else {
            return 0;
        }
    } else {
#ifdef DEBUG
        printf("Was asked for stoplight_wait on non top/right direction %d\n", direction);
#endif
        return -1;
    }
}

bool step_simul(struct simul *simulation) {
    PolicyResult response = simulation->policy(simulation);
#ifdef DEBUG
    printf("Got policy response %d.\n", response);
#endif

    if (response == Right) {
#ifdef DEBUG
        printf("Handling right response\n");
#endif
        if (simulation -> x_right) { // we're at the right, so if we go right now we're crossing the street
            int wait_time = stoplight_wait(simulation, response);
            simulation -> diag.time_waiting += wait_time;
            simulation -> cur_t += simulation->street_width + wait_time;
            simulation -> x_right = false;
            simulation -> current_x += 1;
        } else { // here we're crossing the block
            simulation->cur_t += simulation->block_width;
            simulation->x_right = true;
        }
    } else if (response == Top) {
#ifdef DEBUG
        printf("Handling top response\n");
#endif
        if (simulation -> y_top) { // we're at the top, so we're crossing the street here
            int wait_time = stoplight_wait(simulation, response);
            simulation -> diag.time_waiting += wait_time;
            simulation -> cur_t += simulation->street_width + wait_time;
            simulation -> y_top = false;
            simulation -> current_y += 1;
        } else {
            simulation->cur_t += simulation->block_height;
            simulation->y_top = true;
        }
    } else {
        fprintf(stderr, "Erroneous policy function %p, returned response %d\n", simulation->policy, response);
        return false;
    }

    if (response == Top) {
        // simulation -> diag.move_sequence[simulation -> diag.cur_move /8] |= 1 << (simulation -> diag.cur_move % 8);
    }
    simulation -> diag.cur_move += 1;

    if ((simulation -> current_x + 1) == simulation -> blocks_wide &&
        (simulation -> current_y + 1) == simulation -> blocks_high &&
        simulation -> x_right &&
        simulation -> y_top) {
        return false; // we've reached our destination
    }

    return true;
}

PolicyResult default_policy(struct simul * simulation) {
    if (simulation -> current_y+1 < simulation -> blocks_high || !simulation->y_top) {
        return Top;
    }
    return Right;
}

PolicyResult avoid_waiting_policy(struct simul *simulation) {
    // If we've hit the edges, we have no more options, just continue towards the destination.
    if (simulation -> current_y+1 == simulation -> blocks_high && simulation -> y_top) {
        return Right;
    }
    else if (simulation -> current_x+1 == simulation -> blocks_wide && simulation -> x_right) {
        return Top;
    }

    if (stoplight_wait(simulation, Top) == 0) {
        return Top;
    } else {
        return Right;
    }
}

struct diagnostics simulate(int blocks_wide, int blocks_high, int block_height, int block_width, int stoplight_time, int street_width, PolicyFunc policy) {
    struct simul *simulation = malloc(sizeof(struct simul));

    simulation -> cur_t = 0;
    simulation -> current_x = 0;
    simulation -> current_y = 0;

    simulation -> diag.num_randoms = 0;

    simulation -> blocks_wide = blocks_wide;
    simulation -> blocks_high = blocks_high;
    simulation -> block_width = block_width;
    simulation -> block_height = block_height;
    simulation -> street_width = street_width;

    // diagnostics...
    simulation -> diag.cur_move = 0;
    simulation -> diag.time_waiting = 0;

    simulation -> stoplight_time = stoplight_time;

    simulation -> x_right = false;
    simulation -> y_top = false;
    
    if (blocks_wide > 1000 || blocks_high > 1000) {
        printf("GOT WEIRD PARAMETERS: %d %d\n", blocks_wide, blocks_high);
    }
    int area = (blocks_wide+1) * (blocks_high+1);
    // int calculated_size = (area >> 3)+((area&7) != 0); // /8, rounded up

    simulation -> times = calloc(sizeof(float), area);

    if (!policy) {
        policy = default_policy;
    }
    simulation -> policy = policy;

    // run out the simulation
    while (step_simul(simulation)){}

    struct diagnostics diag = simulation -> diag;

    diag.total_time = simulation -> cur_t;

    free(simulation -> times);
    free(simulation);

    return diag;
}
