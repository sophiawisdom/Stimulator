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
    @public Parameters _params;
}

- (instancetype)initWithBlocksWide: (int) blocksWide blocksHigh: (int) blocksHigh blockHeight: (float) blockHeight blockWidth: (float)blockWidth stoplightTime: (float)stoplightTime streetWidth:(float)streetWidth policy: (PolicyFunc) policy;

+ (instancetype)defaultParams;

- (bool)isEqual: (ParametersObject *)otherParam;
@end

NS_ASSUME_NONNULL_END
