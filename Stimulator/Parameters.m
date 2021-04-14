//
//  Parameters.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "Parameters.h"

@implementation Parameters {
    int _max_time;
    int _min_time;
}

- (instancetype)initWithBlocksWide:(int)blocksWide BlocksHigh:(int)blocksHigh blockHeight:(int)blockHeight blockWidth:(int)blockWidth stoplightTime:(int)stoplightTime streetWidth:(int)streetWidth policy: (PolicyFunc)policy{
    if (self = [super init]) {
        _blocks_wide = blocksWide;
        _blocks_high = blocksHigh;
        _block_height = blockHeight;
        _block_width = blockWidth;
        _stoplight_time = stoplightTime;
        _street_width = streetWidth;
        _policy = policy;
    }
    return self;
}

- (int)max_time {
    if (_max_time == 0) {
        _max_time = self.min_time + _stoplight_time*2*(_blocks_high+_blocks_wide); // this is a shaky calculation...
    }
    return _max_time;
}

- (int)min_time {
    if (_min_time == 0) {
        _min_time = _blocks_wide*_block_width + _blocks_high*_block_height + _street_width*(_blocks_high+_blocks_wide);
    }
    return _min_time;
}

@end
