//
//  SCShaderType.h
//  Athena
//
//  Created by Theresa on 2019/01/16.
//  Copyright © 2019 Theresa. All rights reserved.
//

#ifndef ALCShaderType_h
#define ALCShaderType_h

#include <simd/simd.h>

typedef enum ALCInputIndex {
    ALCInputIndexVertices = 0,
} ALCInputIndex;

typedef enum ALCTextureIndex {
    ALCTextureIndexY = 0,
    ALCTextureIndexUV,
    ALCTextureIndexU,
    ALCTextureIndexV,
} ALCTextureIndex;

typedef struct {
    vector_float2 position;
} ALCVertex;

#endif /* SCShaderType_h */
