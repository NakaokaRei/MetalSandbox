#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(const device Vertex *vertices [[buffer(0)]],
                             uint vertexId [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertices[vertexId].position, 1.0);
    return out;
}

fragment float4 fragment_main_A(VertexOut in [[stage_in]]) {
    // 三角形Aは赤色で描画
    return float4(1, 0, 0, 1);
}

fragment float4 fragment_main_B(VertexOut in [[stage_in]]) {
    // 三角形Bは青色で描画
    return float4(0, 0, 1, 1);
}
