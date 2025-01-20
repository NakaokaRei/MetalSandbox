#include <metal_stdlib>
using namespace metal;

/// 頂点入力構造体
struct VertexIn {
    float3 position [[attribute(0)]];
};

/// 頂点出力構造体 (頂点→フラグメント)
struct VertexOut {
    float4 position [[position]];
    float3 pos;  // 後でフラグメントシェーダーで使えるように
};

/// 頂点シェーダー
vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    // position.xyz を float4(...) に拡張
    out.position = float4(in.position, 1.0);

    // 補間用に pos をそのまま持たせる (x,y,z)
    out.pos = in.position;
    return out;
}

/// フラグメントシェーダー
fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    // 左端 (x = -1) から右端 (x = 1) にかけて 0..1 の値を計算
    // ratio = 0: 赤, ratio = 1: 青
    float ratio = in.pos.x * 0.5 + 0.5;

    // 赤と青を float4 で定義
    float4 red  = float4(1.0, 0.0, 0.0, 1.0);
    float4 blue = float4(0.0, 0.0, 1.0, 1.0);

    // mix(red, blue, ratio) で線形補間
    float4 color = mix(red, blue, ratio);
    return color;
}
