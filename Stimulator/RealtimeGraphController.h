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
#import "PolicyChooserView.h"

@interface RealtimeGraphController : NSViewController<PolicyObserver, PolicyReceiver>

- (instancetype)initWithFrame:(NSRect)frame;

@end

