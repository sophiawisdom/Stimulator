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

NSString *parameters_description(Parameters *params);
Parameters *create_parameters(int blocksWide, int blocksHigh, float blockHeight, float blockWidth, float stoplightTime, float streetWidth, PolicyFunc policy);

NS_ASSUME_NONNULL_END
