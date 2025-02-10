#include <metal_stdlib>
using namespace metal;

// 頂点構造体：位置とテクスチャ座標（uv）
struct Vertex {
    float4 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
};

// 頂点シェーダー出力構造体
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// 頂点シェーダー：各頂点の位置と uv をそのままパススルーする
vertex VertexOut vertex_main(const device Vertex *vertices [[buffer(0)]],
                             uint vertexId [[vertex_id]]) {
    VertexOut out;
    out.position = vertices[vertexId].position;
    out.uv = vertices[vertexId].uv;
    return out;
}

// フラグメントシェーダー：テクスチャとサンプラーから色をサンプルして返す
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> texture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]]) {
    return texture.sample(textureSampler, in.uv);
}
