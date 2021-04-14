//
//  RealtimeGraphRenderer.m
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "RealtimeGraphRenderer.h"
#import "GraphRendererHeaders.h"

@implementation RealtimeGraphRenderer {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    // The render pipeline generated from the vertex and fragment shaders in the .metal shader file.
    id<MTLRenderPipelineState> _firstTrianglePipeline;
    id<MTLRenderPipelineState> _secondTrianglePipeline;
    CGSize _viewportSize;
    Results *_results;
    Parameters *_params;
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
    }
    return self;
}

- (void)setParams: (Parameters *)params andResults: (Results *)results {
    _params = params;
    _results = results;
}

static int num_boxes = 100; // what happens if there are less than 100 possibilites...

- (int *)ranges {
    int min = _params.min_time;
    int max = _params.max_time;
    
    int diff = max-min;
    int *box_ranges = calloc(sizeof(int), num_boxes);
    for (int i = 0; i < num_boxes-1; i++) {
        box_ranges[i] += min + (diff/num_boxes * i);
    }
    box_ranges[num_boxes-1] = max;
    return box_ranges;
}

- (int *)boxes {
    __block int *box_range_values = calloc(sizeof(int), num_boxes);
    int *ranges = self.ranges;
    
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
    
    printf("Boxes: ");
    for (int i = 0; i < num_boxes; i++) {
        printf("%d ", box_range_values[i]);
    }
    printf("\n");

    return box_range_values;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    printf("Time to update the view's contents...\n");
    
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
    int *box_values = self.boxes;
    int box_max = 0;
    for (int i = 0; i < num_boxes; i++) {
        box_max = box_max > box_values[i] ? box_max : box_values[i];
    }
    printf("box_max is %d\n", box_max);
    
    // Draw first triangles
    [commandEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.width, _viewportSize.height, 0.0, 1.0 }];
    [commandEncoder setRenderPipelineState:_firstTrianglePipeline];

    [commandEncoder setVertexBytes:box_values
                           length:sizeof(int)*num_boxes
                          atIndex:GraphRendererInputIndexSquares];
    [commandEncoder setVertexBytes:&box_max length:sizeof(box_max) atIndex:GraphRendererInputIndexBoxTotal];
    [commandEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:GraphRendererInputIndexViewportSize];
    [commandEncoder setVertexBytes:&num_boxes length:sizeof(num_boxes) atIndex:GraphRendererInputIndexNumBoxes];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_boxes*3];
    
    // Draw second triangles
    [commandEncoder setRenderPipelineState:_secondTrianglePipeline];
    [commandEncoder setVertexBytes:box_values
                           length:sizeof(int)*num_boxes
                          atIndex:GraphRendererInputIndexSquares];
    [commandEncoder setVertexBytes:&box_max length:sizeof(box_max) atIndex:GraphRendererInputIndexBoxTotal];
    [commandEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:GraphRendererInputIndexViewportSize];
    [commandEncoder setVertexBytes:&num_boxes length:sizeof(num_boxes) atIndex:GraphRendererInputIndexNumBoxes];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_boxes*3];

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
