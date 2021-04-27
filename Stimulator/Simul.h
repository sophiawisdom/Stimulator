typedef enum PolicyResult {
    Right, // go right, even if it means waiting
    Top, // go top, even if it means waiting.
} PolicyResult;

struct simul;

typedef PolicyResult (*PolicyFunc)(struct simul * test);

struct diagnostics {
    int time_waiting;
    double total_time;
    // char move_sequence[128]; // stored as an *inline* sequence of bools. this means max width+height is 1024
    int cur_move;
    int num_randoms;
};

struct simul {
    struct diagnostics diag;

    int block_height;
    int block_width;
    int blocks_high;
    int blocks_wide;
    int street_width;

    // simulation -> times[effective_x * simulation -> blocks_high + effective_y]
    
    // TODO: remove this if we aren't going to make policies that use it. It's kind of like
    // cheating to use it as well -- obviously IRL this won't exist.
    float *times; // times[3 * simulation -> blocks_high + 6] is block (x=3, y=6)
    char *calculated;

    int current_x; // start at 0, 0
    bool x_right; // true: we're at the right of the block. false: we're at the left of the block
    int current_y;
    bool y_top; // true: we're at the top of the block. false: we're at the bottom of the block

    int cur_t;

    int stoplight_time;

    PolicyFunc policy;
};

struct diagnostics simulate(int blocks_wide, int blocks_high, int block_height, int block_width, int stoplight_time, int street_width, PolicyFunc policy);

PolicyResult avoid_waiting_policy(struct simul *simulation);
PolicyResult default_policy(struct simul *simulation);
