//
//  Mapping.metal
//  Athena
//
//  Created by Theresa on 2019/01/15.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "ALCShaderType.h"
#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mappingVertex(unsigned int vertex_id [[ vertex_id ]],
                                          constant ALCVertex *vertices [[ buffer(ALCInputIndexVertices) ]]) {
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    
    outVertex.renderedCoordinate = float4(vertices[vertex_id].position, 0.0, 1.0);
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 nv12Fragment(TextureMappingVertex mappingVertex [[ stage_in ]],
                               texture2d<float, access::sample> ytexture [[ texture(ALCTextureIndexY) ]],
                               texture2d<float, access::sample> uvtexture [[ texture(ALCTextureIndexUV) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    half3 yuv;
    yuv.x = half4(ytexture.sample(s, mappingVertex.textureCoordinate)).r - (16.0/255.0);
    yuv.yz = half4(uvtexture.sample(s, mappingVertex.textureCoordinate)).rg - half2(0.5, 0.5);
    
    const half3x3 rgb = half3x3(half3(1.164,  1.164, 1.164),
                                half3(0.000, -0.392, 2.017),
                                half3(1.596, -0.813, 0.000));
    
    return half4(rgb * yuv, 1);
}

fragment half4 i420Fragment(TextureMappingVertex mappingVertex [[ stage_in ]],
                           texture2d<float, access::sample> ytexture [[ texture(ALCTextureIndexY) ]],
                           texture2d<float, access::sample> utexture [[ texture(ALCTextureIndexU) ]],
                           texture2d<float, access::sample> vtexture [[ texture(ALCTextureIndexV) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    half y, u, v;
    half3 rgb;
    y = half4(ytexture.sample(s, mappingVertex.textureCoordinate)).r;
    u = half4(utexture.sample(s, mappingVertex.textureCoordinate)).r - 0.5;
    v = half4(vtexture.sample(s, mappingVertex.textureCoordinate)).r - 0.5;
    
    rgb.r = y +             1.402 * v;
    rgb.g = y - 0.344 * u - 0.714 * v;
    rgb.b = y + 1.772 * u;
    
    return half4(rgb, 1);
}
