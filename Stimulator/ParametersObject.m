//
//  ParametersObject.m
//  Stimulator
//
//  Created by Sophia Wisdom on 6/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "ParametersObject.h"

@implementation ParametersObject

- (instancetype)initWithBlocksWide: (int) blocksWide blocksHigh: (int) blocksHigh blockHeight: (float) blockHeight blockWidth: (float)blockWidth stoplightTime: (float)stoplightTime streetWidth:(float)streetWidth policy: (PolicyFunc) policy {
    if (self = [super init]) {
        _params.blocks_wide = blocksWide;
        _params.blocks_high = blocksHigh;
        _params.block_height = blockHeight;
        _params.block_width = blockWidth;
        _params.stoplight_time = stoplightTime;
        _params.street_width = streetWidth;
        _params.policy = policy;
        
        // 5 on either end here is for safety. i know this is bad practice.
        _params.min_time = blocksWide*blockWidth + blocksHigh*blockHeight + streetWidth*(blocksHigh-1+blocksWide-1) - 5;
        _params.max_time = _params.min_time + stoplightTime*2*(blocksHigh+blocksWide) + 10;
        
        return self;
    }
    return nil;
}

- (bool)isEqual:(ParametersObject *)other
{
    return memcmp(&other -> _params, &self -> _params, sizeof(Parameters)) == 0;
}

+ (instancetype)defaultParams {
    return [[ParametersObject alloc] initWithBlocksWide:50 blocksHigh:50 blockHeight:30.0f blockWidth:30.0f stoplightTime:10.0f streetWidth:2.0f policy:default_policy];
}

@end
