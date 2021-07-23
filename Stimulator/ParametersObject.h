//
//  ParametersObject.h
//  Stimulator
//
//  Created by Sophia Wisdom on 6/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simul.h"

NS_ASSUME_NONNULL_BEGIN

@interface ParametersObject : NSObject {
    @public Parameters *params;
}

- (instancetype)initWithBlocksWide: (int) blocksWide blocksHigh: (int) blocksHigh blockHeight: (float) blockHeight blockWidth: (float)blockWidth stoplightTime: (float)stoplightTime streetWidth:(float)streetWidth policy: (PolicyFunc) policy;

@end

NS_ASSUME_NONNULL_END
