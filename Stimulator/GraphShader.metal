#include <metal_stdlib>

using namespace metal;

#include "GraphRendererHeaders.h"

struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];
};

// Bottom triangle
vertex RasterizerData
firstTriangle(uint vertexID [[vertex_id]],
             constant int *inputBoxes [[buffer(GraphRendererInputIndexSquares)]],
             constant int *numBoxesPointer [[buffer(GraphRendererInputIndexNumBoxes)]],
             constant int *maxHeightPointer [[buffer(GraphRendererInputIndexBoxTotal)]])
{
    RasterizerData out;

    int num_boxes = *numBoxesPointer;
    int maxHeight = *maxHeightPointer;
    int box_idx = vertexID/3; // Making a box is two triangles == two shader calls
    float x = (1.8 * float(box_idx)/float(num_boxes)) - .9;
    float y = -.9;
    int whichPoint = vertexID%3; // 0/1/2
    if (whichPoint == 0) { // topleft
        y += (float(inputBoxes[box_idx])/float(maxHeight))*1.8;
    } else if (whichPoint == 2) { // bottomleft
        x += 1.8/num_boxes;
    }
    out.position = vector_float4(x, y, 0.0, 1.0);
    return out;
}

// Top triangle
vertex RasterizerData
secondTriangle(uint vertexID [[vertex_id]],
             constant int *inputBoxes [[buffer(GraphRendererInputIndexSquares)]],
             constant int *numBoxesPointer [[buffer(GraphRendererInputIndexNumBoxes)]],
             constant int *maxHeightPointer [[buffer(GraphRendererInputIndexBoxTotal)]])
{
    RasterizerData out;

    float num_boxes = float(*numBoxesPointer);
    float maxHeight = float(*maxHeightPointer);
    int box_idx = vertexID/3; // Making a box is two triangles == two shader calls
    float x = float(1.8*float(box_idx+1)/num_boxes)-.9;
    float y = (1.8 * float(inputBoxes[box_idx])/float(maxHeight))-.9;
    int whichPoint = vertexID%3; // 0/1/2
    if (whichPoint == 0) { // topleft
        x -= 1.8/float(num_boxes);
    } else if (whichPoint == 2) { // bottomright
        y = -.9;
    }
    out.position = vector_float4(x, y, 0.0, 1.0);
    return out;
}

vertex RasterizerData
tickMarks(uint vertexID [[vertex_id]],
             constant int *inputBoxes [[buffer(GraphRendererInputIndexSquares)]],
             constant int *numBoxesPointer [[buffer(GraphRendererInputIndexNumBoxes)]],
             constant int *maxHeightPointer [[buffer(GraphRendererInputIndexBoxTotal)]])
{
    RasterizerData out;
    
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return float4(0.0, 0.0, 1.0, 1.0);
}
