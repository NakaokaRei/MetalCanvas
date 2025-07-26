import Foundation

struct ShaderExample: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let source: String
}

struct ShaderExamples {
    static let gradient = ShaderExample(
        name: "Gradient",
        description: "Simple animated gradient",
        icon: "paintbrush.fill",
        source: """
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
    )
    
    static let circles = ShaderExample(
        name: "Circles",
        description: "Animated concentric circles",
        icon: "circle.grid.3x3.fill",
        source: """
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
    )
    
    static let plasma = ShaderExample(
        name: "Plasma",
        description: "Classic plasma effect",
        icon: "flame.fill",
        source: """
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
    )
    
    static let mandelbrot = ShaderExample(
        name: "Mandelbrot",
        description: "Fractal explorer",
        icon: "snow",
        source: """
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
    )
    
    static let waves = ShaderExample(
        name: "Waves",
        description: "Ocean wave simulation",
        icon: "waveform.path",
        source: """
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
            
            float wave1 = sin(uv.x * 10.0 + uniforms.u_time * 2.0) * 0.05;
            float wave2 = sin(uv.x * 15.0 - uniforms.u_time * 1.5) * 0.03;
            float wave3 = sin(uv.x * 20.0 + uniforms.u_time * 3.0) * 0.02;
            
            float y = uv.y + wave1 + wave2 + wave3;
            
            float3 color = float3(0.1, 0.3, 0.8);
            color = mix(color, float3(0.6, 0.8, 1.0), smoothstep(0.5, 0.51, y));
            color = mix(color, float3(1.0), smoothstep(0.5, 0.52, y) * 0.5);
            
            return float4(color, 1.0);
        }
        """
    )
    
    static let voronoi = ShaderExample(
        name: "Voronoi",
        description: "Cellular noise pattern",
        icon: "hexagon.fill",
        source: """
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
        
        float2 hash2(float2 p) {
            return fract(sin(float2(dot(p, float2(127.1, 311.7)),
                                  dot(p, float2(269.5, 183.3)))) * 43758.5453);
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                     constant FragmentUniforms& uniforms [[buffer(0)]]) {
            float2 fragCoord = in.position.xy;
            float2 uv = fragCoord / uniforms.u_resolution;
            
            float scale = 10.0;
            uv *= scale;
            
            float2 i_uv = floor(uv);
            float2 f_uv = fract(uv);
            
            float min_dist = 1.0;
            
            for (int y = -1; y <= 1; y++) {
                for (int x = -1; x <= 1; x++) {
                    float2 neighbor = float2(x, y);
                    float2 point = hash2(i_uv + neighbor);
                    point = 0.5 + 0.5 * sin(uniforms.u_time + 6.2831 * point);
                    
                    float2 diff = neighbor + point - f_uv;
                    float dist = length(diff);
                    min_dist = min(min_dist, dist);
                }
            }
            
            float3 color = float3(min_dist);
            color = 1.0 - color;
            color *= float3(0.2, 0.6, 1.0);
            
            return float4(color, 1.0);
        }
        """
    )
    
    static let all: [ShaderExample] = [
        gradient,
        circles,
        plasma,
        mandelbrot,
        waves,
        voronoi
    ]
}