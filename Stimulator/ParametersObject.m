//
//  ParametersObject.m
//  Stimulator
//
//  Created by Sophia Wisdom on 6/1/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "ParametersObject.h"

@implementation ParametersObject

- (instancetype)initWithParameters:(Parameters *)params {
    if (self = [super init]) {
        return self;
    }
    return self;
}

- (void)dealloc
{
    free(self -> params);
}

@end
