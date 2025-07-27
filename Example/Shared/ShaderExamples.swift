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
    
    static let solidRed = ShaderExample(
        name: "Solid Red",
        description: "Simple solid red color",
        icon: "square.fill",
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
            // Simply return red color
            return float4(1.0, 0.0, 0.0, 1.0);
        }
        """
    )
    
    static let textureDemo = ShaderExample(
        name: "Texture Demo",
        description: "Display Metal icon texture with sparkle effects",
        icon: "sparkles",
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
        
        float random(float2 st) {
            return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
        }
        
        float noise(float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);
            
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));
            
            float2 u = f * f * (3.0 - 2.0 * f);
            
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                     constant FragmentUniforms& uniforms [[buffer(0)]],
                                     texture2d<float, access::sample> metalTexture [[texture(0)]]) {
            constexpr sampler textureSampler(mag_filter::linear,
                                           min_filter::linear,
                                           address::clamp_to_edge);
            
            float2 uv = in.texCoord;
            float2 fragCoord = in.position.xy;
            
            // Sample the base texture
            float4 color = metalTexture.sample(textureSampler, uv);
            
            // Add time-based wave effect
            float wave = sin(uv.y * 10.0 + uniforms.u_time * 2.0) * 0.01;
            float2 distortedUV = uv + float2(wave, 0);
            float4 distortedColor = metalTexture.sample(textureSampler, distortedUV);
            color = mix(color, distortedColor, 0.3);
            
            // Calculate sparkle positions
            float sparkleScale = 50.0;
            float2 sparkleUV = fragCoord / sparkleScale;
            
            // Create multiple layers of sparkles
            float sparkle1 = noise(sparkleUV + uniforms.u_time * 0.5);
            float sparkle2 = noise(sparkleUV * 2.0 - uniforms.u_time * 0.3);
            float sparkle3 = noise(sparkleUV * 3.0 + uniforms.u_time * 0.7);
            
            // Make sparkles sharp and bright
            sparkle1 = pow(sparkle1, 8.0) * 2.0;
            sparkle2 = pow(sparkle2, 10.0) * 3.0;
            sparkle3 = pow(sparkle3, 12.0) * 4.0;
            
            // Combine sparkles
            float totalSparkle = sparkle1 + sparkle2 + sparkle3;
            
            // Add rainbow colors to sparkles
            float3 sparkleColor = 0.5 + 0.5 * cos(uniforms.u_time + uv.xyx + float3(0, 2, 4));
            
            // Apply sparkles to the texture
            color.rgb += sparkleColor * totalSparkle * 0.5;
            
            // Add brightness variation
            float brightness = 0.9 + 0.1 * sin(uniforms.u_time * 3.0);
            color.rgb *= brightness;
            
            // Add a subtle glow effect
            float glow = sin(uniforms.u_time * 2.0) * 0.5 + 0.5;
            color.rgb += float3(0.1, 0.2, 0.3) * glow * 0.2;
            
            // Ensure we don't exceed maximum brightness
            color.rgb = clamp(color.rgb, 0.0, 1.0);
            
            return color;
        }
        """
    )
    
    static let mouseTracker = ShaderExample(
        name: "Mouse Tracker",
        description: "Interactive mouse/touch tracking",
        icon: "cursorarrow.rays",
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
            
            // Mouse position in UV coordinates
            float2 mouseUV = uniforms.u_mouse / uniforms.u_resolution;
            
            // Distance from fragment to mouse
            float dist = distance(uv, mouseUV);
            
            // Create ripple effect
            float ripple = sin(dist * 50.0 - uniforms.u_time * 5.0) * 0.5 + 0.5;
            ripple *= exp(-dist * 3.0);
            
            // Background gradient
            float3 bgColor = mix(float3(0.1, 0.1, 0.2), float3(0.2, 0.1, 0.3), uv.y);
            
            // Mouse glow
            float glow = exp(-dist * 5.0);
            float3 glowColor = float3(0.5, 0.8, 1.0) * glow;
            
            // Combine effects
            float3 color = bgColor + glowColor + ripple * float3(0.2, 0.4, 0.8);
            
            // Add a cursor indicator
            if (dist < 0.02) {
                color = float3(1.0);
            }
            
            return float4(color, 1.0);
        }
        """
    )
    
    static let all: [ShaderExample] = [
        solidRed,
        gradient,
        circles,
        plasma,
        mandelbrot,
        waves,
        voronoi,
        textureDemo,
        mouseTracker
    ]
}