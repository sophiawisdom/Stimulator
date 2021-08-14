//
//  ViewController.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Simul.h"
#import "ParamsChooserView.h"

static const int max_array_size = 32768; // Max difference between max and min for a parameter. Otherwise the backing array will be too small.

@interface RealtimeGraphController : NSViewController<ParamsReceiver>

- (instancetype)initWithFrame:(NSRect)frame;

@end

