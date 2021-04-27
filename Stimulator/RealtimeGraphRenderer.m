//
//  RealtimeGraphRenderer.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "RealtimeGraphRenderer.h"
#import "GraphRendererHeaders.h"

#import <SpriteKit/SpriteKit.h>

@implementation RealtimeGraphRenderer {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    // The render pipeline generated from the vertex and fragment shaders in the .metal shader file.
    id<MTLRenderPipelineState> _firstTrianglePipeline;
    id<MTLRenderPipelineState> _secondTrianglePipeline;
    CGSize _viewportSize;
    Results *_results;
    Parameters *_params;
    SKRenderer *_renderer;
}

- (instancetype)initWithMTKView:(MTKView *)view {
    if (self = [super init]) {
        _device = view.device;
        
        // Load all the shader files with a .metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        id<MTLFunction> firstTriangleFunction = [defaultLibrary newFunctionWithName:@"firstTriangle"];
        id<MTLFunction> secondTriangleFunction = [defaultLibrary newFunctionWithName:@"secondTriangle"];
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
        printf("setting initial size to %g %g\n", _viewportSize.height, _viewportSize.width);
        
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

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
        
        _renderer = [SKRenderer rendererWithDevice:_device];
        _renderer.scene = [[SKScene alloc] initWithSize:_viewportSize];
        SKLabelNode *node = [SKLabelNode labelNodeWithText:@"Hey! This is a really long piece of text!"];
        node.color = [NSColor blackColor];
        node.fontSize = 100;
        node.fontName = @"Arial";
        [_renderer.scene addChild:node];
    }
    return self;
}

- (void)setParams: (Parameters *)params andResults: (Results *)results {
    _params = params;
    _results = results;
}

- (int)num_boxes {
    int min = _params -> _min_time;
    int max = _params -> _max_time;
    int diff = max-min;
    
    int pixel_width = _viewportSize.width * graph_width/3; // at least 3 pixels per bar

    return diff > pixel_width ? pixel_width : diff; // min(diff, pixel_width)
}

- (int *)ranges: (int)boxes { // not ideal that you're going to have some boxes with different widths...
    int min = _params -> _min_time;
    int max = _params -> _max_time;
    int diff = max-min;

    int *box_ranges = calloc(sizeof(int), boxes);
    for (int i = 0; i < boxes-1; i++) {
        box_ranges[i] += min + (diff/boxes * i);
    }
    box_ranges[boxes-1] = max;
    return box_ranges;
}

- (int *)boxes: (int)num_boxes {
    __block int *box_range_values = calloc(sizeof(int), num_boxes);
    int *ranges = [self ranges:num_boxes];
    
    [_results acquireLock:^(int * _Nonnull results, int min, int max) {
        int range_idx = 0;
        for (int i = 0; i < max-min; i++) {
            int result = results[i];
            while (min+i > ranges[range_idx]) {
                range_idx++;
            }
            box_range_values[range_idx] += result;
        }
    }];
    
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
    // printf("box_max is %d\n", box_max);
    
    NSPoint mouseLocation = [NSEvent mouseLocation];
        
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
