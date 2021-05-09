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

static const int num_threads = 4;

@implementation RealtimeGraphController {
    NSMutableArray<SimulatorThread *> *_threadpool;
    Results *_results;
    MTKView *_view;
    RealtimeGraphRenderer *_renderer;
}

// Should we cache previously calculated results? Probably unlikely we would hit the *exact* combination

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


- (void)change_policy:(PolicyFunc)new_policy {
    if (new_policy != _params -> policy) {
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, _params -> block_width, _params -> stoplight_time, _params -> street_width, new_policy);
    }
    // TODO: CHANGE LABEL SO USER KNOWS WHICH ONE IS DEFAULT AND WHICH ONE IS BETTER
}

- (IBAction)WidthChanged:(NSSlider *)sender {
    if (sender.intValue != _params -> block_width) {
        // printf("Modifying block width, is now %d\n", sender.intValue);
        self.params = create_parameters(_params -> blocks_wide, _params -> blocks_high, _params -> block_height, sender.intValue, _params -> stoplight_time, _params -> street_width, _params -> policy);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"self.view is %@\n", self.view);
    
    srandomdev();
    
    _view = (MTKView *)self.view;
        
    _view.device = MTLCreateSystemDefaultDevice();
    
    _view.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0); // white
    
    _renderer = [[RealtimeGraphRenderer alloc] initWithMTKView:_view];
    _view.delegate = _renderer;
    
    _threadpool = [[NSMutableArray alloc] initWithCapacity:num_threads];
    for (int i = 0; i < num_threads; i++) {
        [_threadpool addObject:[[SimulatorThread alloc] init]];
    }
    self.params = create_parameters(50, 50, 10, 10, 4.0, 5, default_policy);
}

- (void)dealloc
{
    free(_params);
}

- (void)setParams:(Parameters *)params {
    Parameters *old_params = _params;
    _params = params;
    [self invalidate];
    free(old_params);
}

- (void)invalidate {
    _results = [[Results alloc] initWithMin:_params -> min_time Max:_params -> max_time MaxWriters:num_threads];
    [_threadpool enumerateObjectsUsingBlock:^(SimulatorThread * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
        [thread newParams:_params andResults:_results];
    }];
    [_renderer setParams:_params andResults:_results];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
