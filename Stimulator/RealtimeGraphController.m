//
//  ViewController.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/12/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "RealtimeGraphController.h"

#import <CoreGraphics/CoreGraphics.h>

#include "ParametersObject.h"
#import "SimulatorThread.h"
#import "RealtimeGraphRenderer.h"
#import "PolicyCompiler.h"
#import "ParamsChooserView.h"

static const unsigned int num_threads = 4;

@implementation RealtimeGraphController {
    NSRect _frame;
    NSMutableArray<SimulatorThread *> *_threadpool;
    Results *_results;
    MTKView *_view;
    RealtimeGraphRenderer *_distribution_renderer;
    PolicyCompiler *_policycompiler;
    ParametersObject *_params;
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

    ParamsChooserView *params_chooser = [[ParamsChooserView alloc] initWithFrame:NSMakeRect(500, 300, 500, 400) andDelegate:self];
    [self.view addSubview:params_chooser];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    srandomdev();

    _policycompiler = [[PolicyCompiler alloc] initWithObject:self];

    _threadpool = [[NSMutableArray alloc] initWithCapacity:num_threads];
    for (int i = 0; i < num_threads; i++) {
        [_threadpool addObject:[[SimulatorThread alloc] init]];
    }
    self.params = [ParametersObject defaultParams];
    // printf("self params min_time is %d max_time is %d\n", _params -> min_time, _params -> max_time);
}

- (void)setParams:(ParametersObject *)params {
    _params = params;
    _results = [[Results alloc] initWithMin:_params -> _params.min_time Max:_params -> _params.max_time MaxWriters:num_threads];
    [_threadpool enumerateObjectsUsingBlock:^(SimulatorThread * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
        [thread newParams:_params andResults:_results];
    }];
    [_distribution_renderer setParams:_params andResults:_results];
}

@end
