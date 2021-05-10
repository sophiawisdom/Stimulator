typedef enum PolicyResult {
    Right, // go right, even if it means waiting
    Top, // go top, even if it means waiting.
} PolicyResult;

struct simul;

typedef PolicyResult (*PolicyFunc)(struct simul * test);

typedef struct Parameters {
    int blocks_wide;
    int blocks_high;
    float block_height;
    float block_width;
    float stoplight_time;
    float street_width;
    PolicyFunc policy;

    int max_time;
    int min_time;
} Parameters;

Parameters *create_parameters(int blocksWide, int blocksHigh, float blockHeight, float blockWidth, float stoplightTime, float streetWidth, PolicyFunc policy);

struct diagnostics {
    int time_waiting;
    double total_time;
    // char move_sequence[128]; // stored as an *inline* sequence of bools. this means max width+height is 1024
    int cur_move;
    int num_randoms;
};

struct simul {
    struct diagnostics diag;
    Parameters params;
    // simulation -> times[effective_x * simulation -> blocks_high + effective_y]
    
    // TODO: remove this if we aren't going to make policies that use it. It's kind of like
    // cheating to use it as well -- obviously IRL this won't exist.
    float *times; // times[3 * simulation -> blocks_high + 6] is block (x=3, y=6)
    char *calculated;

    int current_x; // start at 0, 0
    bool x_right; // true: we're at the right of the block. false: we're at the left of the block
    int current_y;
    bool y_top; // true: we're at the top of the block. false: we're at the bottom of the block

    float cur_t;
};

struct diagnostics simulate(Parameters *params);

PolicyResult avoid_waiting_policy(struct simul *simulation);
PolicyResult default_policy(struct simul *simulation);
PolicyResult faster_policy(struct simul *simulation);
