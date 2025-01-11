#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant float4x4& rotationMatrix [[buffer(1)]]) {
    VertexOut out;
    out.position = rotationMatrix * float4(in.position, 1.0);
    out.position.z = out.position.z * 0.5 + 0.5;
    return out;
}

fragment float4 fragment_main() {
    return float4(0.4, 0.6, 0.8, 1.0);  // 青色
}
