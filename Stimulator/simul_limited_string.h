//
//  simul_limited_string.h
//  Stimulator
//
//  Created by Sophia Wisdom on 10/17/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#ifndef simul_limited_string_h
#define simul_limited_string_h

static char *simul_limited_string = "typedef enum PolicyResult {\
    Right,\
    Top,\
} PolicyResult;\
\
struct simul;\
\
typedef PolicyResult (*PolicyFunc)(struct simul * current_state);\
\
typedef struct {\
    int blocks_wide;\
    int blocks_high;\
    float block_height;\
    float block_width;\
    float stoplight_time;\
    float street_width;\
    PolicyFunc policy;\
\
    int max_time;\
    int min_time;\
\
    long long magic;\
} Parameters;\
\
struct simul {\
    Parameters params;\
\
    float *times;\
    char *calculated;\
\
    int current_x;\
    int x_right;\
    int current_y;\
    int y_top;\
\
    float cur_t;\
\
    double rand_quotient;\
    double twice_stoplight_time;\
    double half_stoplight_time;\
};";

#endif /* simul_limited_string_h */
