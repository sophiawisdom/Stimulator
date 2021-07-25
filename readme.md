**Project overview**
In a manhattan distance world, all paths between point A and point B are the same. If you add traffic lights into this equation, things become more complex. In terms of distance, all paths are still the same, but in terms of time, some paths will have less waiting time than others. This project was originally an attempt to prove to myself what the optimal policy is for walking in such a world, and how much time such a policy would save over a naive policy.

**Technical Details**
The simulation is totally contained within `simul.c`.  The rest of the project is about giving the user knobs to tweak the simulation and exposing the results as quickly as possible.

The simulation was deliberately made to be as simple as possible, in order to improve performance. This enables use-cases like moving a slider and seeing new simulation results on every frame.

The `Parameters` struct in `simul.h` defines the parameters to the simulation. The crucial function is `simulate()` which takes a `Parameters` struct and returns the time taken.

The mental model of the simulation is that we are in a manhattan distance world, `blocks_wide` blocks wide and `blocks_high` blocks high, where each block has a y distance of `block_height` and an x distance of  `block_width` wide. We start at the bottom-left corner of block (0, 0) and need to go to the top-right corner of block (`blocks_high`, `blocks_wide`). Because we are going from the bottom-left to the top-right, there are only two directions we can go: `Top` or `Right`. Every time we have to make a decision on where to go, we call a `policy` function, which takes the current state and decides whether to go `Top` or `Right`. Sometimes, the policy will have to wait at a stoplight. The goal of creating this simulation is to find the policy that does this the least.

Currently there are three policies implemented:
* Default policy: Go `Top` until we can't anymore, then go `Right`
* Avoid waiting policy: Go `Top` if that light is green, otherwise go `Right`
* Faster policy: Same as avoid waiting policy, but attempt to stay on an approximately diagonal path so as to reduce the likelihood we get stuck along the edges.



