//
//  RendererHeaders.h
//  Stimulator
//
//  Created by Sophia Wisdom on 4/13/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#ifndef RendererHeaders_h
#define RendererHeaders_h

#include <simd/simd.h>

typedef enum GraphRendererInputIndex {
    GraphRendererInputIndexSquares = 0,
    GraphRendererInputIndexNumBoxes = 1,
    GraphRendererInputIndexBoxTotal = 2
} GraphRendererInputIndex;

// Sharing constants is difficult because they can change -- easier to share an include.
#define graph_width (0.9)

#endif /* RendererHeaders_h */
