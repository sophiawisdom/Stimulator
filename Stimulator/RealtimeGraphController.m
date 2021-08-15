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
#import "ParamsChooserView.h"

@implementation RealtimeGraphController {
    NSRect _frame;
    NSMutableArray<SimulatorThread *> *_threadpool;
    Results *_results;
    MTKView *_view;
    RealtimeGraphRenderer *_distribution_renderer;
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
    self.view = [[MTKView alloc] initWithFrame:_frame device:MTLCreateSystemDefaultDevice()];
    NSLog(@"MTKView's frame is %@\n", NSStringFromRect(self.view.frame));
    self.view.frame = _frame;
    _view = (MTKView *)self.view;
    _view.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0); // white
    _distribution_renderer = [[RealtimeGraphRenderer alloc] initWithMTKView:_view];
    _view.delegate = _distribution_renderer;

    ParamsChooserView *params_chooser = [[ParamsChooserView alloc] initWithFrame:NSMakeRect(500, 300, 500, 400) andDelegate:self];
    [self.view addSubview:params_chooser];
    _results = [[Results alloc] initWithNumThreads:8];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    srandomdev();

    printf("Setting initial default params\n");
    [self setParams:[ParametersObject defaultParams] andFunction:@"default_policy"];
    // printf("self params min_time is %d max_time is %d\n", _params -> min_time, _params -> max_time);
}

- (void)setParams:(ParametersObject *)params andFunction:(nonnull NSString *)function {
    // TOTHINKABOUT: does setting params in distribution renderer here have the possibility of threading issues? my general assumption is that the distribution renderer is all UI code, as is the ParamsChooserView, and as such it'll always be on the main thread. Better make sure!
    if (![NSThread isMainThread]) {
        fprintf(stderr, "SETPARAMS CALLED ON NOT THE MAIN THREAD!!! stacktrace: %s", [[[NSThread callStackSymbols] description] UTF8String]);
    }
    [_results setParams:params function:function];
    [_distribution_renderer setParams:params andResults:_results];
}

@end
