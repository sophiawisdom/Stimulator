//
//  ViewController.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Simul.h"
#import "PolicyCompiler.h"
#import "ParamsChooserView.h"

@interface RealtimeGraphController : NSViewController<PolicyObserver, ParamsReceiver>

@property Parameters *params;

- (instancetype)initWithFrame:(NSRect)frame;

@end

