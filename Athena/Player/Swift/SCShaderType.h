//
//  SCShaderType.h
//  Athena
//
//  Created by Theresa on 2019/01/16.
//  Copyright © 2019 Theresa. All rights reserved.
//

#ifndef SCShaderType_h
#define SCShaderType_h

#include <simd/simd.h>

typedef enum SCInputIndex {
    SCInputIndexVertices = 0,
} SCInputIndex;

typedef enum SCTextureIndex {
    SCTextureIndexY = 0,
    SCTextureIndexUV,
    SCTextureIndexU,
    SCTextureIndexV,
} SCTextureIndex;

typedef struct {
    vector_float2 position;
} SCVertex;

#endif /* SCShaderType_h */
