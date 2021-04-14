//
//  RealtimeGraphRenderer.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

#import "Parameters.h"
#import "Results.h"

NS_ASSUME_NONNULL_BEGIN

@interface RealtimeGraphRenderer : NSObject <MTKViewDelegate>

- (instancetype)initWithMTKView: (MTKView *)view;

- (void)setParams: (Parameters *)params andResults: (Results *)results;

@end

NS_ASSUME_NONNULL_END
