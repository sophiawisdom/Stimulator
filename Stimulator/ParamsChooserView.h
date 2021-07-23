//
//  ParamsChooserView.h
//  Stimulator
//
//  Created by Sophia Wisdom on 5/30/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PolicyChooserView.h"
#import "Simul.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ParamsReceiver <NSObject>

- (void)setParams: (Parameters *)params;

@end

@interface ParamsChooserView : NSView <PolicyReceiver>

- (instancetype)initWithFrame:(NSRect)frame andDelegate:(id<ParamsReceiver>)delegate NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
