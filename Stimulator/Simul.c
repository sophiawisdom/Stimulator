#include "stdbool.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "Simul.h"
#include <x86intrin.h>

static inline void FastRand(fastrand *f)
{
    __m128i a = _mm_load_si128((const __m128i *)f->a);
    __m128i b = _mm_load_si128((const __m128i *)f->b);
    
    const __m128i mask = _mm_load_si128((const __m128i *)f->mask);
    const __m128i m1 = _mm_load_si128((const __m128i *)f->m1);
    const __m128i m2 = _mm_load_si128((const __m128i *)f->m2);
    
    __m128i amask = _mm_and_si128(a, mask);
    __m128i ashift = _mm_srli_epi32(a, 0x10);
    __m128i amul = _mm_mullo_epi32(amask, m1);
    __m128i anew = _mm_add_epi32(amul, ashift);
    _mm_store_si128((__m128i *)f->a, anew);
    
    __m128i bmask = _mm_and_si128(b, mask);
    __m128i bshift = _mm_srli_epi32(b, 0x10);
    __m128i bmul = _mm_mullo_epi32(bmask, m2);
    __m128i bnew = _mm_add_epi32(bmul, bshift);
    _mm_store_si128((__m128i *)f->b, bnew);
    
    __m128i bmasknew = _mm_and_si128(bnew, mask);
    __m128i ashiftnew = _mm_slli_epi32(anew, 0x10);
    __m128i res = _mm_add_epi32(ashiftnew, bmasknew);
    _mm_store_si128((__m128i *)f->res, res);
    
    f -> used = 0;
}

__thread fastrand global_rand;
 
// How long is the stoplight's cycle time
static double get_stoplight_time(struct simul *simulation, int x, int y) {
    // Instead of pre-calculating the stoplight times, we load them dynamically
    int index = x * simulation->params.blocks_high + y;
    // the existence of the cache saves us ~500ns/simulate()
    if (simulation->times[index] == 0) {
        if (simulation -> rand -> used == 4) {
            FastRand(simulation -> rand);
        }
        // value from stoplight_time/2 to 3*stoplight_time/2
        double value = (double)random()/*global_rand.res[global_rand.used++]*//(double)(simulation->rand_quotient) + simulation->half_stoplight_time;
        simulation->times[index] = value;
        return value;
    }
    return simulation->times[index];
}

static double stoplight_wait(struct simul *simulation, PolicyResult direction) {
    // TODO: how to account for the fact this is useless to e.g. ask stoplight wait to go top if there's no light top
    int effective_x = simulation->current_x - !simulation->x_right + 1;
    int effective_y = simulation->current_y - !simulation->y_top + 1;
#ifdef SIMUL_DEBUG
    printf("effective_x is %d, effective_y is %d\n", effective_x, effective_y);
#endif
    
    // The whole system cycles every s_t*2 seconds. get_stoplight_time returns when "top" switches to "right", which can be from .5-1.5*s_t
    double stoplight_time = get_stoplight_time(simulation, effective_x, effective_y);
    float cycle_time = simulation->twice_stoplight_time;
    float current_time = fmodf(simulation->cur_t, cycle_time);
    if (direction == Top) {
        if (current_time <= stoplight_time) { // Green light to go Top
            return 0;
        } else {
            return cycle_time - current_time;
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

__attribute__((noinline)) bool step_simul(struct simul *simulation) {
    PolicyResult response;
    if (simulation -> current_y+1 == simulation -> params.blocks_high && simulation -> y_top) {
        response = Right; // we're at the top edge
    }
    else if (simulation -> current_x+1 == simulation -> params.blocks_wide && simulation -> x_right) {
        response = Top; // we're at the right edge
    } else {
        response = simulation -> params.policy(simulation); // default path
    }

    if (response == Right) {
        if (simulation -> x_right) { // we're at the right, so if we go right now we're crossing the street
            double wait_time = stoplight_wait(simulation, response);
            simulation -> cur_t += simulation -> params.street_width + wait_time;
            simulation -> x_right = false;
            simulation -> current_x += 1;
        } else { // here we're crossing the block
            simulation -> cur_t += simulation -> params.block_width;
            simulation -> x_right = true;
        }
    } else if (response == Top) {
        if (simulation -> y_top) { // we're at the top, so we're crossing the street here
            double wait_time = stoplight_wait(simulation, response);
            simulation -> cur_t += simulation -> params.street_width + wait_time;
            simulation -> y_top = false;
            simulation -> current_y += 1;
        } else {
            simulation -> cur_t += simulation -> params.block_height;
            simulation -> y_top = true;
        }
    } else {
        fprintf(stderr, "Erroneous policy function %p, returned response %d\n", simulation -> params.policy, response);
        return false;
    }

    if ((simulation -> current_x + 1) == simulation -> params.blocks_wide &&
        (simulation -> current_y + 1) == simulation -> params.blocks_high &&
        simulation -> x_right &&
        simulation -> y_top) {
        return false; // we've reached our destination
    }

    return true;
}

PolicyResult default_policy(struct simul * simulation) {
    return Top;
}

PolicyResult avoid_waiting_policy(struct simul *simulation) {
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

PolicyResult wait_more_policy(struct simul *simulation) {
    if (!simulation -> x_right && !simulation -> y_top) {
        // We're at the bottom-left, which means there's no stoplight to look at in any case, so just go top as a default.
        return Top;
    }

    if (simulation -> x_right && !simulation -> y_top) {
        // We're at the bottom-right. We should try to go right if there's no wait, but otherwise we'll go top.
        if (stoplight_wait(simulation, Right) != 0) {
            return Right;
        }
        return Top;
    }

    if (!simulation -> x_right && simulation -> y_top) {
        // We're at the top-left, so same as bottom-right but reversed.
        if (stoplight_wait(simulation, Top) != 0) {
            return Top;
        }
        return Right;
    }

    // If we're at the top-right, just go whichever way doesn't have a wait.
    if (stoplight_wait(simulation, Top) != 0) {
        return Top;
    } else {
        return Right;
    }
}

// If we're off course, off the ideal diagonal, start sacrificing a little waiting time to get closer to the diagonal.
PolicyResult faster_policy(struct simul *simulation) {
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

double simulate(Parameters params) {
    struct simul *simulation = malloc(sizeof(struct simul));

    simulation -> cur_t = 0;
    simulation -> current_x = 0;
    simulation -> current_y = 0;
    
    simulation -> params = params;

    // diagnostics...

    simulation -> x_right = false;
    simulation -> y_top = false;
    
    simulation -> rand_quotient = RAND_MAX/*4294967295*//(simulation->params.stoplight_time);
    simulation -> half_stoplight_time = simulation->params.stoplight_time/2;
    simulation -> twice_stoplight_time = simulation->params.stoplight_time*2;
    
    if (simulation -> params.magic != 0xCAFEBEEF || abs(simulation -> params.blocks_wide) > 1000 || abs(simulation -> params.blocks_high > 1000)) {
        printf("GOT WEIRD PARAMETERS: %p %d %d\n", simulation -> params.magic, simulation -> params.blocks_wide, simulation -> params.blocks_high);
    }
    int area = (simulation -> params.blocks_wide+1) * (simulation -> params.blocks_high+1);
    // int calculated_size = (area >> 3)+((area&7) != 0); // /8, rounded up

    simulation -> times = calloc(sizeof(float), area);
    
    simulation -> rand = &global_rand;

    if (!simulation -> params.policy) {
       simulation -> params.policy = default_policy;
    }

    // run out the simulation
    while (step_simul(simulation)){}
    
    double retval = simulation -> cur_t;

    free(simulation -> times);
    free(simulation);

    return retval;
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
