#include <metal_stdlib>

using namespace metal;

#include "GraphRendererHeaders.h"

struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];
    bool MeanLine; // If it's for the mean line. This is dumb because it carries runtime cost for what should be a compile-time distinction. But overall it's fine, should reduce complexity slightly.
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
    float x = (graph_width * 2 * float(box_idx)/float(num_boxes)) - graph_width;
    float y = -graph_width;
    int whichPoint = vertexID%3; // 0/1/2
    if (whichPoint == 0) { // topleft
        y += (float(inputBoxes[box_idx])/float(maxHeight))*graph_width*2;
    } else if (whichPoint == 2) { // bottomleft
        x += (graph_width*2)/num_boxes;
    }
    out.position = vector_float4(x, y, 0.0, 1.0);
    out.MeanLine = false;
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
    float x = float(graph_width*2*float(box_idx+1)/num_boxes)-graph_width;
    float y = (graph_width*2 * float(inputBoxes[box_idx])/float(maxHeight))-graph_width;
    int whichPoint = vertexID%3; // 0/1/2
    if (whichPoint == 0) { // topleft
        x -= graph_width*2/float(num_boxes);
    } else if (whichPoint == 2) { // bottomright
        y = -graph_width;
    }
    out.position = vector_float4(x, y, 0.0, 1.0);
    out.MeanLine = false;
    return out;
}

vertex RasterizerData
meanLine(uint vertexID [[vertex_id]],constant float *meanPointer [[buffer(MeanLineInputIndexMean)]])
{
    RasterizerData out;
    float mean = float(*meanPointer); // value between 0 and 1.
    float x = (mean*1.8)-0.9f;
    if (!(vertexID & 1)) { // first point
        out.position = vector_float4(x, -.9, 0.0, 1.0);
    } else { // second point
        out.position = vector_float4(x, .9, 0.0, 1.0);
    }
    
    out.MeanLine = true;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    if (in.MeanLine) {
        return float4(1.0, 0.0, 0.0, 1.0); // red
    } else {
        return float4(0.0, 0.0, 1.0, 1.0); // blue
    }
}
