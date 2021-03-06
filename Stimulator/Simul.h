#include <stdbool.h>
#include <stdlib.h>

typedef enum PolicyResult {
    Right, // go right, even if it means waiting
    Top, // go top, even if it means waiting.
} PolicyResult;

struct simul;

typedef PolicyResult (*PolicyFunc)(struct simul * current_state);

typedef struct {
    int blocks_wide;
    int blocks_high;
    float block_height;
    float block_width;
    float stoplight_time;
    float street_width;
    PolicyFunc policy;

    int max_time;
    int min_time;
    
    long long magic; // detect corruption
} Parameters;

struct simul {
    Parameters params;
    // simulation -> times[effective_x * simulation -> blocks_high + effective_y]
    
    // TODO: remove this if we aren't going to make policies that use it. It's kind of like
    // cheating to use it as well -- obviously IRL this won't exist.
    float *times; // times[3 * simulation -> blocks_high + 6] is block (x=3, y=6)
    char *calculated;

    int current_x; // start at 0, 0
    int x_right; // true: we're at the right of the block. false: we're at the left of the block
    int current_y;
    int y_top; // true: we're at the top of the block. false: we're at the bottom of the block

    float cur_t;
    
    // Caches. It's probably faster to get these values from l1 cache than it is to calculate them...
    double rand_quotient;
    double twice_stoplight_time;
    double half_stoplight_time;
};

#define SPEED_CHECK 0

double simulate(Parameters params);

PolicyResult avoid_waiting_policy(struct simul *simulation);
PolicyResult default_policy(struct simul *simulation);
PolicyResult faster_policy(struct simul *simulation);

// Showed in the UI from bottom to top
static const char* policies[4] = {
    "faster_policy",
    "avoid_waiting_policy",
    "default_policy",
    "wait_more_policy"
};

// Parameters *create_parameters(int blocksWide, int blocksHigh, float blockHeight, float blockWidth, float stoplightTime, float streetWidth, PolicyFunc policy);
// bool parameters_equal(Parameters *first, Parameters *second);
// create_parameters(50, 50, 30, 30, 10.0, 2, default_policy)

const static Parameters default_params = {
    .blocks_wide = 50,
    .blocks_high = 50,
    .block_height = 30.0f,
    .block_width = 30.0f,
    .stoplight_time = 10.0f,
    .street_width = 2.0f,
    .policy = default_policy,
    .min_time = 3196,
    .max_time = 5196
};
