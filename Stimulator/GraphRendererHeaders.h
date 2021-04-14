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
    GraphRendererInputIndexViewportSize = 1,
    GraphRendererInputIndexNumBoxes = 2,
    GraphRendererInputIndexBoxTotal = 3
} GraphRendererInputIndex;

#endif /* RendererHeaders_h */
