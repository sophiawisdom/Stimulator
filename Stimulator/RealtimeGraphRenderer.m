//
//  RealtimeGraphRenderer.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "RealtimeGraphRenderer.h"
#import "GraphRendererHeaders.h"
#import "SimulatorThread.h"

#import <sys/time.h>

#import <SpriteKit/SpriteKit.h>

@implementation RealtimeGraphRenderer {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    // The render pipeline generated from the vertex and fragment shaders in the .metal shader file.
    id<MTLRenderPipelineState> _firstTrianglePipeline;
    id<MTLRenderPipelineState> _secondTrianglePipeline;
    id<MTLRenderPipelineState> _meanLinePipeline;
    CGSize _viewportSize;
    Results *_results;
    ParametersObject *_params;
    
    // We use SceneKit for rendering text because the quantity of text we have to render is minimal, and doing text rendering on the GPU
    // seems quite difficult.
    SKRenderer *_renderer;
    SKLabelNode *_textNode;
    SKLabelNode *_min_node;
    SKLabelNode *_max_node;
}

- (instancetype)initWithMTKView:(MTKView *)view {
    if (self = [super init]) {
        _device = view.device;

        // Load all the shader files with a .metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        id<MTLFunction> firstTriangleFunction = [defaultLibrary newFunctionWithName:@"firstTriangle"];
        id<MTLFunction> secondTriangleFunction = [defaultLibrary newFunctionWithName:@"secondTriangle"];
        id<MTLFunction> meanLineFunction = [defaultLibrary newFunctionWithName:@"meanLine"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        // Configure a pipeline descriptor that is used to create a pipeline state.
        MTLRenderPipelineDescriptor *firstTriangleStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        firstTriangleStateDescriptor.label = @"First triangle Pipeline";
        firstTriangleStateDescriptor.vertexFunction = firstTriangleFunction;
        firstTriangleStateDescriptor.fragmentFunction = fragmentFunction;
        firstTriangleStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        NSError *error;
        _firstTrianglePipeline = [_device newRenderPipelineStateWithDescriptor:firstTriangleStateDescriptor error:&error];
        if (error != nil) {
            NSLog(@"Encountered error with setting up first pipeline: %@", error);
        }

        _viewportSize = view.drawableSize;

        MTLRenderPipelineDescriptor *secondTriangleStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        secondTriangleStateDescriptor.label = @"Second triangle Pipeline";
        secondTriangleStateDescriptor.vertexFunction = secondTriangleFunction;
        secondTriangleStateDescriptor.fragmentFunction = fragmentFunction;
        secondTriangleStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        NSError *secondError;
        _secondTrianglePipeline = [_device newRenderPipelineStateWithDescriptor:secondTriangleStateDescriptor error:&secondError];
        if (secondError != nil) {
            NSLog(@"Encountered error with setting up second pipeline: %@", secondError);
        }

        MTLRenderPipelineDescriptor *meanLineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        meanLineStateDescriptor.label = @"Mean line Pipeline";
        meanLineStateDescriptor.vertexFunction = meanLineFunction;
        meanLineStateDescriptor.fragmentFunction = fragmentFunction;
        meanLineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        NSError *thirdError;
        _meanLinePipeline = [_device newRenderPipelineStateWithDescriptor:meanLineStateDescriptor error:&thirdError];
        if (thirdError != nil) {
            NSLog(@"Encountered error with setting up mean line pipeline: %@", secondError);
        }

        // Create the command queue
        _commandQueue = [_device newCommandQueue];

        _renderer = [SKRenderer rendererWithDevice:_device];
        _renderer.scene = [[SKScene alloc] initWithSize:_viewportSize];

        _textNode = [SKLabelNode labelNodeWithText:@"Hey!"];
        _textNode.fontColor = [NSColor blackColor];
        _textNode.fontSize = 20;
        _textNode.fontName = @"Arial";
        _textNode.hidden = true;

        _min_node = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        _min_node.position = CGPointMake(100, 20);

        _max_node = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        _max_node.position = CGPointMake(800, 20);

        [@[_min_node, _max_node] enumerateObjectsUsingBlock:^(SKLabelNode *  _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            node.fontColor = [NSColor blackColor];
            node.fontSize = 20;
            node.hidden = false;
            [_renderer.scene addChild:node];
        }];

        [_renderer.scene addChild:_textNode];
        NSLog(@"Succeeded Initializing RealtimeGraphRenderer, view is %@", view);
    }
    return self;
}

- (void)setParams: (ParametersObject *)params andResults: (Results *)results {
    // MAIN THREAD ONLY
    _params = params;
    _results = results;
}

#define min(a,b) ((a) > (b) ? (b) : (a))

- (int)num_boxes {
    int max_screen_boxes = _viewportSize.width * graph_width/3;
    int max_vertex_boxes = 1000; // boxes array must be < 4096 bytes, so max 1000 integers.
    int max_range_boxes = RESULTS_SPECIFICITY_MULTIPLIER*(_params-> _params.max_time - _params->_params.min_time);
    return min(min(max_screen_boxes, max_vertex_boxes), max_range_boxes);
}

- (float)mean {
    // Not ideal to be doing two readValues calls. We could put this in box and have that update it.
    __block double total = 0;
    __block double count = 0;
    [_results readValues:^(_Atomic int * _Nonnull results, int min, int max) {
        double diff = (max-min)*RESULTS_SPECIFICITY_MULTIPLIER;
        for (int i = 0; i < diff; i++) {
            total += (i * results[i])/diff; // Ultimately we want a value between 0 and 1 for use in the UI.
            count += results[i];
        }
    }];
    return total/count;
}


- (int *)boxes: (int)num_boxes {
    __block int *box_range_values = calloc(sizeof(int), num_boxes);
    // printf("num_boxes is %d\n", nu)

    [_results readValues:^(_Atomic int * _Nonnull results, int min, int max) {
        int length = (max-min)*RESULTS_SPECIFICITY_MULTIPLIER;
        for (int i = 0; i < length; i++) {
            int index = (i*num_boxes)/length;
            box_range_values[index] += results[i];
        }
    }];
    
    /*
    for (int i = 0; i < num_boxes; i++) {
        box_range_values[i] = 1;
    }
     */
    
    /*
    printf("Boxes: ");
    for (int i = 0; i < num_boxes; i++) {
        printf("%d ", box_range_values[i]);
    }
    printf("\n");
     */

    return box_range_values;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    if (!_params || !_results) {
        printf("Refusing to render...\n");
        return;
    }

    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor == nil) {
        return;
    }

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

    // generate data...
    int num_boxes = [self num_boxes];
    int *box_values = [self boxes:num_boxes];
    int box_max = 0;
    for (int i = 0; i < num_boxes; i++) {
        box_max = box_max > box_values[i] ? box_max : box_values[i];
    }
    float mean = self.mean;
    // printf("box_max is %d\n", box_max);

#ifdef SPEED_CHECK
    struct timeval tv;
    gettimeofday(&tv, NULL);
    long long time = tv.tv_sec*1000*1000 + tv.tv_usec;
    long long diff = time - _results.beginning;
    double t_diff = diff/(1000000.0);
    double time_taken = diff/(_results.num_results > 0 ? _results.num_results : 1);
    printf("It's been %g seconds and there have been %lld results written (%g µs/results)\n", t_diff, _results.num_results, time_taken);
#endif

    CGPoint mouseLocation = [NSEvent mouseLocation];
    _textNode.position = CGPointMake(mouseLocation.x*2, mouseLocation.y*2);
    _textNode.text = [NSString stringWithFormat:@"%f%%", mean*100];
    _textNode.hidden = false;

    _max_node.text = [NSString stringWithFormat:@"%d", _params -> _params.max_time];
    _min_node.text = [NSString stringWithFormat:@"%d", _params -> _params.min_time];
    // _max_node.position = CGPointMake(mouseLocation.x*2-350, mouseLocation.y*2-300);
    // _min_node.position = CGPointMake(mouseLocation.x*2-250, mouseLocation.y*2-300);

    // Draw first triangles
    [commandEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.width, _viewportSize.height, 0.0, 1.0 }];
    [commandEncoder setRenderPipelineState:_firstTrianglePipeline];

    [commandEncoder setVertexBytes:box_values
                           length:sizeof(int)*num_boxes
                          atIndex:GraphRendererInputIndexSquares];
    [commandEncoder setVertexBytes:&box_max length:sizeof(box_max) atIndex:GraphRendererInputIndexBoxTotal];
    [commandEncoder setVertexBytes:&num_boxes length:sizeof(num_boxes) atIndex:GraphRendererInputIndexNumBoxes];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_boxes*3];

    // Draw second triangles
    [commandEncoder setRenderPipelineState:_secondTrianglePipeline];
    [commandEncoder setVertexBytes:box_values
                           length:sizeof(int)*num_boxes
                          atIndex:GraphRendererInputIndexSquares];
    [commandEncoder setVertexBytes:&box_max length:sizeof(box_max) atIndex:GraphRendererInputIndexBoxTotal];
    [commandEncoder setVertexBytes:&num_boxes length:sizeof(num_boxes) atIndex:GraphRendererInputIndexNumBoxes];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_boxes*3];

    [commandEncoder setRenderPipelineState:_meanLinePipeline];
    [commandEncoder setVertexBytes:&mean
                           length:sizeof(float)
                          atIndex:MeanLineInputIndexMean];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:2];

    [_renderer renderWithViewport:CGRectMake(0, 0, _viewportSize.width, _viewportSize.height) renderCommandEncoder:commandEncoder renderPassDescriptor:renderPassDescriptor commandQueue:_commandQueue];

    [commandEncoder endEncoding];

    id<MTLDrawable> drawable = view.currentDrawable;

    // Request that the drawable texture be presented by the windowing system once drawing is done
    [commandBuffer presentDrawable:drawable];

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    printf("The drawable size will change, we're told... %g %g\n", size.height, size.width);
    _viewportSize = size;
}

@end
