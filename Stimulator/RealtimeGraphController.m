//
//  ViewController.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "RealtimeGraphController.h"

#import <CoreGraphics/CoreGraphics.h>

#include "Simul.h"
#import "SimulatorThread.h"
#import "RealtimeGraphRenderer.h"
#import "PolicyCompiler.h"
#import "PolicyChooserView.h"

static const unsigned int num_threads = 1;

@implementation RealtimeGraphController {
    NSRect _frame;
    NSMutableArray<SimulatorThread *> *_threadpool;
    Results *_results;
    MTKView *_view;
    RealtimeGraphRenderer *_distribution_renderer;
    PolicyCompiler *_policycompiler;
    Parameters *_params;
    PolicyFunc _compiled_policy;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    if (self = [super init]) {
        _frame = frame;
    }
    return self;
}

- (void)loadView {
    NSLog(@"RealtimeGraphController's loadView was called... parent frame is %@\n", NSStringFromRect(_frame));
    /*
    self.view = [[NSView alloc] initWithFrame:_frame];
    NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    [self.view addSubview:button];
     */
    self.view = [[MTKView alloc] initWithFrame:_frame device:MTLCreateSystemDefaultDevice()];
    NSLog(@"MTKView's frame is %@\n", NSStringFromRect(self.view.frame));
    self.view.frame = _frame;
    _view = (MTKView *)self.view;
    _view.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0); // white
    _distribution_renderer = [[RealtimeGraphRenderer alloc] initWithMTKView:_view];
    _view.delegate = _distribution_renderer;
    
    NSButton *button = [NSButton buttonWithTitle:@"Button!" target:self action:@selector(buttonPressed)];
    
    button.frame = NSMakeRect(100, 100, 100, 100);
    button.bezelColor = [NSColor systemPinkColor];
    [self.view addSubview:button];
    
    [self.view addSubview:[[PolicyChooserView alloc] initWithFrame:NSMakeRect(100, 300, 100, 400) andDelegate:self]];
}

- (void)buttonPressed {
    printf("Button was pressed. SEL is %s\n", _cmd);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    srandomdev();

    _policycompiler = [[PolicyCompiler alloc] initWithObject:self];

    _threadpool = [[NSMutableArray alloc] initWithCapacity:num_threads];
    for (int i = 0; i < num_threads; i++) {
        [_threadpool addObject:[[SimulatorThread alloc] init]];
    }
    self.params = create_parameters(50, 50, 30, 30, 10.0, 2, default_policy);
}

// MARK: handle button presses
/*
- (IBAction)HeightChanged:(NSSlider *)sender {
    if (sender.intValue != _params -> block_height) {
        // printf("Modifying height, is now %d\n", sender.intValue);
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, sender.intValue, _params -> block_width, _params -> stoplight_time, _params -> street_width, _params -> policy);
    }
}

- (IBAction)StoplightTimeChanged:(NSSlider *)sender {
    if (sender.floatValue != _params -> stoplight_time) {
        // printf("Modifying stoplight time, is now %d\n", sender.intValue);
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, _params -> block_width, sender.floatValue, _params -> street_width, _params -> policy);
    }
}
- (IBAction)DefaultPolicySet:(NSButton *)sender {
    [self change_policy:default_policy];
}
- (IBAction)BetterPolicySet:(NSButton *)sender {
    [self change_policy:avoid_waiting_policy];
}
- (IBAction)BestPolicySet:(NSButton *)sender {
    [self change_policy:faster_policy];
}
 */

/*
- (IBAction)WidthChanged:(NSSlider *)sender {
    if (sender.intValue != _params -> block_width) {
        // printf("Modifying block width, is now %d\n", sender.intValue);
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, sender.intValue, _params -> stoplight_time, _params -> street_width, _params -> policy);
    }
}
 */

- (void)dealloc
{
    free(_params);
}

- (void)setParams:(Parameters *)params {
    Parameters *old_params = _params;
    _params = params;
    [self invalidate];
    if (old_params != params) { // This is why I probably should have kept Parameters as an object...
        free(old_params);
    }
}

- (void)invalidate {
    _results = [[Results alloc] initWithMin:_params -> min_time Max:_params -> max_time MaxWriters:num_threads];
    [_threadpool enumerateObjectsUsingBlock:^(SimulatorThread * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
        [thread newParams:_params andResults:_results];
    }];
    [_distribution_renderer setParams:_params andResults:_results];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)setCompiledPolicy:(nonnull PolicyFunc)policy {
    _compiled_policy = policy;
}

- (void)policyChanged:(nonnull PolicyFunc)newPolicy {
    if (newPolicy != _params -> policy) {
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, _params -> block_width, _params -> stoplight_time, _params -> street_width, newPolicy);
    }
}

@end
