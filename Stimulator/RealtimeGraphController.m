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
    if (sender.intValue != _params -> _block_height) {
        // printf("Modifying height, is now %d\n", sender.intValue);
        self.params = [[Parameters alloc] initWithBlocksWide:_params -> _blocks_wide BlocksHigh:_params -> _blocks_high blockHeight:sender.intValue blockWidth:_params ->_block_width stoplightTime:_params -> _stoplight_time streetWidth:_params -> _street_width policy:_params -> _policy];
    }
}

- (IBAction)StoplightTimeChanged:(NSSlider *)sender {
    if (sender.floatValue != _params -> _stoplight_time) {
        // printf("Modifying stoplight time, is now %d\n", sender.intValue);
        Parameters *new_params = [[Parameters alloc] initWithBlocksWide:_params -> _blocks_wide BlocksHigh:_params -> _blocks_high blockHeight:_params -> _block_height blockWidth:_params ->_block_width stoplightTime:sender.floatValue streetWidth:_params -> _street_width policy:_params -> _policy];
        self.params = new_params;
    }
}

- (IBAction)WidthChanged:(NSSlider *)sender {
    if (sender.intValue != _params -> _block_width) {
        // printf("Modifying block width, is now %d\n", sender.intValue);
        self.params = [[Parameters alloc] initWithBlocksWide:_params -> _blocks_wide BlocksHigh:_params -> _blocks_high blockHeight:_params -> _block_height blockWidth:sender.intValue stoplightTime:_params -> _stoplight_time streetWidth:_params -> _street_width policy:_params -> _policy];
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
    self.params = [[Parameters alloc] initWithBlocksWide:30 BlocksHigh:50 blockHeight:10 blockWidth:10 stoplightTime:2 streetWidth:5 policy:default_policy];
}

- (void)setParams:(Parameters *)params {
    _params = params;
    [self invalidate];
}

- (void)invalidate {
    _results = [[Results alloc] initWithMin:_params -> _min_time Max:_params -> _max_time];
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
