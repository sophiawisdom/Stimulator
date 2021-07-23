#include "stdbool.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "Simul.h"

// How long is the stoplight's cycle time
double get_stoplight_time(struct simul *simulation, int x, int y) {
    // Instead of pre-calculating the stoplight times, we load them dynamically
    int index = x * simulation -> params.blocks_high + y;
    if (simulation -> times[index] == 0) {
        // value from stoplight_time/2 to 3*stoplight_time/2
        double value = (double)random()/(double)(simulation -> rand_quotient) + simulation->half_stoplight_time;
        simulation -> times[index] = value;
        return value;
    }
    return simulation -> times[index];
}

double stoplight_wait(struct simul *simulation, PolicyResult direction) {
    // TODO: how to account for the fact this is useless to e.g. ask stoplight wait to go top if there's no light top
    int effective_x = simulation -> current_x - !simulation->x_right + 1;
    int effective_y = simulation -> current_y - !simulation->y_top + 1;
#ifdef SIMUL_DEBUG
    printf("effective_x is %d, effective_y is %d\n", effective_x, effective_y);
#endif
    
    // get_stoplight_time returns its cycle time, which is evenly split between top and right. Starts top then goes right.
    double stoplight_time = get_stoplight_time(simulation, effective_x, effective_y);
    double twice_stoplight_time = stoplight_time*2;
    float current_time = fmodf(simulation -> cur_t, twice_stoplight_time);
    if (direction == Top) {
        if (current_time <= stoplight_time) { // Green light to go Top
            return 0;
        } else {
            return (twice_stoplight_time - current_time);
        }
    } else if (direction == Right) {
        if (current_time < stoplight_time) {
            return stoplight_time - current_time;
        } else {
            return 0;
        }
    } else {
#ifdef SIMUL_DEBUG
        printf("Was asked for stoplight_wait on non top/right direction %d\n", direction);
#endif
        return -1;
    }
}

bool step_simul(struct simul *simulation) {
    PolicyResult response = simulation->params.policy(simulation);
#ifdef SIMUL_DEBUG
    printf("Got policy response %d.\n", response);
#endif

    if (response == Right) {
#ifdef SIMUL_DEBUG
        printf("Handling right response\n");
#endif
        if (simulation -> x_right) { // we're at the right, so if we go right now we're crossing the street
            double wait_time = stoplight_wait(simulation, response);
            simulation -> diag.time_waiting += wait_time;
            simulation -> cur_t += simulation->params.street_width + wait_time;
            simulation -> x_right = false;
            simulation -> current_x += 1;
        } else { // here we're crossing the block
            simulation->cur_t += simulation->params.block_width;
            simulation->x_right = true;
        }
    } else if (response == Top) {
#ifdef SIMUL_DEBUG
        printf("Handling top response\n");
#endif
        if (simulation -> y_top) { // we're at the top, so we're crossing the street here
            double wait_time = stoplight_wait(simulation, response);
            simulation -> diag.time_waiting += wait_time;
            simulation -> cur_t += simulation->params.street_width + wait_time;
            simulation -> y_top = false;
            simulation -> current_y += 1;
        } else {
            simulation->cur_t += simulation->params.block_height;
            simulation->y_top = true;
        }
    } else {
        fprintf(stderr, "Erroneous policy function %p, returned response %d\n", simulation->params.policy, response);
        return false;
    }

    if (response == Top) {
        // simulation -> diag.move_sequence[simulation -> diag.cur_move /8] |= 1 << (simulation -> diag.cur_move % 8);
    }
    simulation -> diag.cur_move += 1;

    if ((simulation -> current_x + 1) == simulation -> params.blocks_wide &&
        (simulation -> current_y + 1) == simulation -> params.blocks_high &&
        simulation -> x_right &&
        simulation -> y_top) {
        return false; // we've reached our destination
    }

    return true;
}

PolicyResult default_policy(struct simul * simulation) {
    if (simulation -> current_y+1 < simulation -> params.blocks_high || !simulation->y_top) {
        return Top;
    }
    return Right;
}

PolicyResult avoid_waiting_policy(struct simul *simulation) {
    // If we've hit the edges, we have no more options, just continue towards the destination.
    if (simulation -> current_y+1 == simulation -> params.blocks_high && simulation -> y_top) {
        return Right;
    }
    else if (simulation -> current_x+1 == simulation -> params.blocks_wide && simulation -> x_right) {
        return Top;
    }

    if (stoplight_wait(simulation, Top) == 0) {
        return Top;
    } else {
        return Right;
    }
}

PolicyResult avoid_waiting_policy_2(struct simul *simulation) {
    // If we've hit the edges, we have no more options, just continue towards the destination.
    if (simulation -> current_y+1 == simulation -> params.blocks_high && simulation -> y_top) {
        return Right;
    }
    else if (simulation -> current_x+1 == simulation -> params.blocks_wide && simulation -> x_right) {
        return Top;
    }
    
    if (!simulation -> x_right && !simulation -> y_top) {
        // We're at the bottom-left, which means there's no stoplight to look at in any case, so just go top as a default.
        return Top;
    }
    
    if (simulation -> x_right && !simulation -> y_top) {
        // We're at the bottom-right. We should try to go right if there's no wait, but otherwise we'll go top.
        if (stoplight_wait(simulation, Right) == 0) {
            return Right;
        }
        return Top;
    }
    
    if (!simulation -> x_right && simulation -> y_top) {
        // We're at the top-left, so same as bottom-right but reversed.
        if (stoplight_wait(simulation, Top) == 0) {
            return Top;
        }
        return Right;
    }
    
    // If we're at the top-right, just go whichever way doesn't have a wait.
    if (stoplight_wait(simulation, Top) == 0) {
        return Top;
    } else {
        return Right;
    }
}

// If we're off course, off the ideal diagonal, start sacrificing a little waiting time to get closer to the diagonal.
PolicyResult faster_policy(struct simul *simulation) {
    // If we've hit the edges, we have no more options, just continue towards the destination.
    if (simulation -> current_y+1 == simulation -> params.blocks_high && simulation -> y_top) {
        return Right;
    }
    else if (simulation -> current_x+1 == simulation -> params.blocks_wide && simulation -> x_right) {
        return Top;
    }
    
    // how "steep" is the way we're trying to go?
    double grade = ((double) simulation -> params.blocks_wide) / ((double) simulation -> params.blocks_high);
    double diagonal_current_y = grade * simulation -> current_x;
    double blocks_off_diagonal = diagonal_current_y - simulation -> current_y;
    // if this is positive, it means we're below where we need to be -- we should prioritize Top. If it's negative, we should prioritize
    // Right.

    double top_stoplight_time = stoplight_wait(simulation, Top);
    
    if (blocks_off_diagonal > 5) { // Want to go top if feasible
        // 20 blocks off, tolerate up to 4s. 10 blocks off, tolerate up to 2s, etc.
        if (top_stoplight_time < blocks_off_diagonal/5) {
            return Top;
        }
        return Right;
    }
    if (blocks_off_diagonal < -5) { // Want to go right if feasible
        if (top_stoplight_time > 0) { // if top_stoplight_time > 0, right_stoplight_time == 0, so we can just go. This is a perf optimization.
            return Right;
        }

        double right_stoplight_time = stoplight_wait(simulation, Right);
        // 20 blocks off, tolerate up to 4s. 10 blocks off, tolerate up to 2s, etc.
        if (right_stoplight_time < fabs(blocks_off_diagonal)/5) {
            return Right;
        }
        return Top;
    }

    // We're on track, so just go whichever way can be gone immediately.
    if (top_stoplight_time == 0) {
        return Top;
    } else {
        return Right;
    }
}

PolicyResult faster_policy_2(struct simul *simulation) {
    // If we've hit the edges, we have no more options, just continue towards the destination.
    if (simulation -> current_y+1 == simulation -> params.blocks_high && simulation -> y_top) {
        return Right;
    }
    else if (simulation -> current_x+1 == simulation -> params.blocks_wide && simulation -> x_right) {
        return Top;
    }
    
    // how "steep" is the way we're trying to go?
    double grade = ((double) simulation -> params.blocks_wide) / ((double) simulation -> params.blocks_high);
    double diagonal_current_y = grade * simulation -> current_x;
    double blocks_off_diagonal = diagonal_current_y - simulation -> current_y;
    // if this is positive, it means we're below where we need to be -- we should prioritize Top. If it's negative, we should prioritize
    // Right.
    
    // We're at the bottom-left. Go whichever way is closer to diagonal.
    if (!simulation -> y_top && !simulation -> x_right) {
        if (blocks_off_diagonal > 0) {
            return Top;
        } else {
            return Right;
        }
    }
    
    double top_stoplight_time = stoplight_wait(simulation, Top);
    
    // We're at the top-left. Always go top if it's no wait, and take the wait to go top if we want to go that way and the light isn't too long. otherwise go right.
    if (simulation -> y_top && !simulation -> x_right) {
        if (top_stoplight_time == 0) { // if it's a free street just go.
            return Top;
        }
        
        // if the lights short and we want to go top go top also.
        // TBD: should we wait to go top if it's really short even if we don't want to go that way? seems not great because
        // if we go right we just get a chance to go right, and if we don't get that we'll go top there. if we go top and wait we'll
        // always then go right and have the chance to take the right there?... not sure !
        if (blocks_off_diagonal > 0 && top_stoplight_time < (blocks_off_diagonal/5)) {
            return Top;
        }
        
        // otherwise go right
        return Right;
    }
    
    // same as above
    if (!simulation -> y_top && simulation -> x_right) {
        if (top_stoplight_time != 0) {
            return Right;
        }

        if (blocks_off_diagonal < 0 && -stoplight_wait(simulation, Right) > (blocks_off_diagonal)/5) {
            return Right;
        }
        
        return Top;
    }

    if (blocks_off_diagonal > 5) { // Want to go top if feasible
        // 20 blocks off, tolerate up to 4s. 10 blocks off, tolerate up to 2s, etc.
        if (top_stoplight_time < blocks_off_diagonal/5) {
            return Top;
        }
        return Right;
    }
    if (blocks_off_diagonal < -5) { // Want to go right if feasible
        if (top_stoplight_time > 0) { // if top_stoplight_time > 0, right_stoplight_time == 0, so we can just go. This is a perf optimization.
            return Right;
        }

        double right_stoplight_time = stoplight_wait(simulation, Right);
        // 20 blocks off, tolerate up to 4s. 10 blocks off, tolerate up to 2s, etc.
        if (right_stoplight_time < fabs(blocks_off_diagonal)/5) {
            return Right;
        }
        return Top;
    }

    // We're on track, so just go whichever way can be gone immediately.
    if (top_stoplight_time == 0) {
        return Top;
    } else {
        return Right;
    }
}

struct diagnostics simulate(Parameters *params) {
    struct simul *simulation = malloc(sizeof(struct simul));

    simulation -> cur_t = 0;
    simulation -> current_x = 0;
    simulation -> current_y = 0;

    simulation -> diag.num_randoms = 0;
    
    simulation -> params = *params;

    // diagnostics...
    simulation -> diag.cur_move = 0;
    simulation -> diag.time_waiting = 0;

    simulation -> x_right = false;
    simulation -> y_top = false;
    
    simulation -> rand_quotient = RAND_MAX/(simulation->params.stoplight_time);
    simulation -> half_stoplight_time = simulation->params.stoplight_time/2;
    simulation -> twice_stoplight_time = simulation->params.stoplight_time*2;
    
    if (simulation -> params.blocks_wide > 1000 || simulation -> params.blocks_high > 1000) {
        printf("GOT WEIRD PARAMETERS: %d %d\n", simulation -> params.blocks_wide, simulation -> params.blocks_high);
    }
    int area = (simulation -> params.blocks_wide+1) * (simulation -> params.blocks_high+1);
    // int calculated_size = (area >> 3)+((area&7) != 0); // /8, rounded up

    simulation -> times = calloc(sizeof(float), area);

    if (!simulation -> params.policy) {
       simulation -> params.policy = default_policy;
    }

    // run out the simulation
    while (step_simul(simulation)){}

    struct diagnostics diag = simulation -> diag;

    diag.total_time = simulation -> cur_t;

    free(simulation -> times);
    free(simulation);

    return diag;
}

Parameters *create_parameters(int blocksWide, int blocksHigh, float blockHeight, float blockWidth, float stoplightTime, float streetWidth, PolicyFunc policy) {
    Parameters *params = calloc(sizeof(Parameters), 1);
    params -> blocks_wide = blocksWide;
    params -> blocks_high = blocksHigh;
    params -> block_height = blockHeight;
    params -> block_width = blockWidth;
    params -> stoplight_time = stoplightTime;
    params -> street_width = streetWidth;
    params -> policy = policy;
    
    // extra 5 here is for safety. i know this is dumb
    params -> min_time = blocksWide*blockWidth + blocksHigh*blockHeight + streetWidth*(blocksHigh-1+blocksWide-1) - 5;
    params -> max_time = params -> min_time + stoplightTime*2*(blocksHigh+blocksWide) + 10;
    return params;
}

bool parameters_equal(Parameters *restrict first, Parameters *restrict second) {
    return memcmp(first, second, sizeof(Parameters)) == 0;
}

/*
 int blocks_wide;
 int blocks_high;
 float block_height;
 float block_width;
 float stoplight_time;
 float street_width;
 PolicyFunc policy;

 int max_time;
 int min_time;
 */

char *parameters_description(Parameters *params) {
    char *out = NULL;
    asprintf(&out, "{blocks_wide = %d, blocks_high = %d, block_height = %g, block_width = %g, stoplight_time = %g, street_width = %g, policy = %p, min_time = %d, max_time = %d", params -> blocks_wide, params -> blocks_high, params -> block_height, params -> block_width, params -> stoplight_time, params -> street_width, params -> policy, params -> min_time, params -> max_time);
    return out;
}
