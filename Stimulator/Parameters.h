//
//  Parameters.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Simul.h"

NS_ASSUME_NONNULL_BEGIN

// "Parameters" is a *very* simple wrapper over a set of numbers.
@interface Parameters : NSObject {
    @public int _blocks_wide;
    @public int _blocks_high;
    @public float _block_height;
    @public float _block_width;
    @public float _stoplight_time;
    @public float _street_width;
    @public PolicyFunc _policy;

    @public int _min_time;
    @public int _max_time;
};

- (instancetype)initWithBlocksWide:(int)blocksWide BlocksHigh:(int)blocksHigh blockHeight:(float)blockHeight blockWidth:(float)blockWidth stoplightTime:(float)stoplightTime streetWidth:(float)streetWidth policy: (PolicyFunc)policy;

@end

NS_ASSUME_NONNULL_END
