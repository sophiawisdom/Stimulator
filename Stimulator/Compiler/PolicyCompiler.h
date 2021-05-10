//
//  PolicyCompiler.h
//  Stimulator
//
//  Created by Sophia Wisdom on 5/9/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simul.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PolicyObserver <NSObject>

- (void)setCompiledPolicy: (PolicyFunc)policy;

@end

@interface PolicyCompiler : NSObject

// Callback for when policy has changed. Passed one argument, a function.
- (instancetype)initWithObject:(id<PolicyObserver>)obj;

- (void)setCode:(NSString *)code;

@end

NS_ASSUME_NONNULL_END
