import SwiftUI
import MetalCanvas

@main
struct MetalCanvasExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var fragmentShader: String? = simpleGradientShader
    @State private var selectedExample = 0
    
    let examples = [
        ("Gradient", simpleGradientShader),
        ("Circles", circlesShader),
        ("Plasma", plasmaShader),
        ("Mandelbrot", mandelbrotShader)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            MetalCanvasView(fragmentShader: $fragmentShader)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Picker("Shader", selection: $selectedExample) {
                ForEach(0..<examples.count, id: \.self) { index in
                    Text(examples[index].0).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedExample) { newValue in
                fragmentShader = examples[newValue].1
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// Metal shader examples (written in Metal Shading Language)
let simpleGradientShader = """
#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    float2 u_resolution;
    float u_time;
    float2 u_mouse;
    float4 u_date;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant FragmentUniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float3 color = float3(uv.x, uv.y, 0.5 + 0.5 * sin(uniforms.u_time));
    return float4(color, 1.0);
}
"""

let circlesShader = """
#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    float2 u_resolution;
    float u_time;
    float2 u_mouse;
    float4 u_date;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant FragmentUniforms& uniforms [[buffer(0)]]) {
    float2 fragCoord = in.position.xy;
    float2 uv = (fragCoord - 0.5 * uniforms.u_resolution) / min(uniforms.u_resolution.x, uniforms.u_resolution.y);
    
    float d = length(uv);
    float3 color = float3(1.0 - step(0.3, d));
    
    uv = fract(uv * 5.0) - 0.5;
    d = length(uv);
    color *= float3(1.0 - step(0.2, d));
    
    color *= float3(0.3, 0.6, 1.0);
    color += 0.1 * sin(uniforms.u_time);
    
    return float4(color, 1.0);
}
"""

let plasmaShader = """
#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    float2 u_resolution;
    float u_time;
    float2 u_mouse;
    float4 u_date;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant FragmentUniforms& uniforms [[buffer(0)]]) {
    float2 fragCoord = in.position.xy;
    float2 uv = fragCoord / uniforms.u_resolution;
    
    float time = uniforms.u_time;
    
    float v1 = sin(uv.x * 10.0 + time);
    float v2 = sin(10.0 * (uv.x * sin(time / 2.0) + uv.y * cos(time / 3.0)) + time);
    float cx = uv.x + 0.5 * sin(time / 5.0);
    float cy = uv.y + 0.5 * cos(time / 3.0);
    float v3 = sin(sqrt(100.0 * (cx * cx + cy * cy) + 1.0) + time);
    
    float v = v1 + v2 + v3;
    
    float3 color = float3(sin(v), sin(v + 2.0), sin(v + 4.0));
    color = 0.5 + 0.5 * color;
    
    return float4(color, 1.0);
}
"""

let mandelbrotShader = """
#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    float2 u_resolution;
    float u_time;
    float2 u_mouse;
    float4 u_date;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant FragmentUniforms& uniforms [[buffer(0)]]) {
    float2 fragCoord = in.position.xy;
    float2 uv = (fragCoord - 0.5 * uniforms.u_resolution) / min(uniforms.u_resolution.x, uniforms.u_resolution.y);
    
    float zoom = 1.0 + sin(uniforms.u_time * 0.1) * 0.5;
    uv *= 3.0 / zoom;
    
    float2 c = uv;
    float2 z = float2(0.0);
    
    int iter = 0;
    const int max_iter = 100;
    
    for (int i = 0; i < max_iter; i++) {
        if (dot(z, z) > 4.0) break;
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iter = i;
    }
    
    float smooth_iter = float(iter) + 1.0 - log2(log2(dot(z, z))) / 2.0;
    float3 color = 0.5 + 0.5 * cos(3.0 + smooth_iter * 0.15 + float3(0.0, 0.6, 1.0));
    
    return float4(color, 1.0);
}
"""