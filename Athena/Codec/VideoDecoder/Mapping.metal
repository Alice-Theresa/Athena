//
//  Mapping.metal
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCShaderType.h"
#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mappingVertex(unsigned int vertex_id [[ vertex_id ]],
                                          constant AAPLVertex *vertices [[ buffer(0) ]]) {
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    
    outVertex.renderedCoordinate = float4(vertices[vertex_id].position, 0.0, 1.0);
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 mappingFragment(TextureMappingVertex mappingVertex [[ stage_in ]],
                               texture2d<float, access::sample> ytexture [[ texture(0) ]],
                               texture2d<float, access::sample> uvtexture [[ texture(1) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    half3 yuv;
    yuv.x = half4(ytexture.sample(s, mappingVertex.textureCoordinate)).r - (16.0/255.0);
    yuv.yz = half4(uvtexture.sample(s, mappingVertex.textureCoordinate)).rg - half2(0.5, 0.5);
    
    const half3x3 rgb = half3x3(half3(1.164,  1.164, 1.164),
                                half3(0.000, -0.392, 2.017),
                                half3(1.596, -0.813, 0.000));
    
    return half4(rgb * yuv, 1);
}
