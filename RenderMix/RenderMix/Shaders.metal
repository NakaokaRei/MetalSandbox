#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 pos;
};

/// 頂点シェーダー
vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.pos = in.position;
    return out;
}


//fragment float4 fragment_main(VertexOut in [[stage_in]]) {
//    float ratioX = in.pos.x * 0.5 + 0.5;
//    float ratioY = in.pos.y * 0.5 + 0.5;
//
//    float4 red  = float4(1.0, 0.0, 0.0, 1.0);
//    float4 blue = float4(0.0, 0.0, 1.0, 1.0);
//    float4 green = float4(0.0, 1.0, 0.0, 1.0);
//    float4 yellow = float4(1.0, 1.0, 0.0, 1.0);
//
//    float4 color = mix (mix (red, blue, ratioX), mix (green, yellow, ratioX), ratioY);
//    return color;
//}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    float4 red  = float4(1.0, 0.0, 0.0, 1.0);
    float4 blue = float4(0.0, 0.0, 1.0, 1.0);
    float4 green = float4(0.0, 1.0, 0.0, 1.0);
    float4 yellow = float4(1.0, 1.0, 0.0, 1.0);

    float2 pos = float2(in.pos.x * 0.5 + 0.5, in.pos.y * 0.5 + 0.5);
    float n = 4.0;

    pos = pos * n;
    pos = floor(pos) + step(0.5, fract(pos));
    pos = pos / n;
    float4 color = mix (mix (red, blue, pos.x), mix (green, yellow, pos.x), pos.y);
    return color;
}
