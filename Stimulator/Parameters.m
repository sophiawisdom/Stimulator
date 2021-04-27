//
//  Parameters.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Parameters.h"

@implementation Parameters

- (instancetype)initWithBlocksWide:(int)blocksWide BlocksHigh:(int)blocksHigh blockHeight:(int)blockHeight blockWidth:(int)blockWidth stoplightTime:(int)stoplightTime streetWidth:(int)streetWidth policy: (PolicyFunc)policy{
    if (self = [super init]) {
        _blocks_wide = blocksWide;
        _blocks_high = blocksHigh;
        _block_height = blockHeight;
        _block_width = blockWidth;
        _stoplight_time = stoplightTime;
        _street_width = streetWidth;
        _policy = policy;
        
        _min_time = _blocks_wide*_block_width + _blocks_high*_block_height + _street_width*(_blocks_high-1+_blocks_wide-1);
        _max_time = _min_time + _stoplight_time*2*(_blocks_high+_blocks_wide);
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{blocks_wide: %d, blocks_high: %d, block_height: %d, block_width: %d, stoplight_time: %d, street_width: %d, policy: %p}", _blocks_wide, _blocks_high, _block_height, _block_width, _stoplight_time, _street_width, _policy];
}

@end
