//
//  Parameters.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Parameters.h"

Parameters *create_parameters(int blocksWide, int blocksHigh, float blockHeight, float blockWidth, float stoplightTime, float streetWidth, PolicyFunc policy) {
    Parameters *params = calloc(sizeof(Parameters), 1);
    params -> blocks_wide = blocksWide;
    params -> blocks_high = blocksHigh;
    params -> block_height = blockHeight;
    params -> block_width = blockWidth;
    params -> stoplight_time = stoplightTime;
    params -> street_width = streetWidth;
    params -> policy = policy;

    params -> min_time = blocksWide*blockWidth + blocksHigh*blockHeight + streetWidth*(blocksHigh-1+blocksWide-1);
    params -> max_time = params -> min_time + stoplightTime*2*(blocksHigh+blocksWide);
    return params;
}

NSString *parameters_description(Parameters *params) {
    return [NSString stringWithFormat:@"{blocks_wide: %d, blocks_high: %d, block_height: %f, block_width: %f, stoplight_time: %f, street_width: %f, policy: %p}", params -> blocks_wide, params -> blocks_high, params -> block_height, params -> block_width, params -> stoplight_time, params -> street_width, params -> policy];
}
