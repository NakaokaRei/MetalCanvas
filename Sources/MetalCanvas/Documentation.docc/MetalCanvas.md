# ``MetalCanvas``

A Swift library for rendering Metal shaders with SwiftUI integration, inspired by glsl-canvas.

## Overview

MetalCanvas provides an easy-to-use interface for rendering fragment shaders on macOS and iOS. It automatically handles shader compilation, provides built-in uniforms, and integrates seamlessly with SwiftUI.

### Quick Start

Here's a simple example to get you started:

```swift
import MetalCanvas
import SwiftUI

struct ContentView: View {
    @State private var shaderCode: String? = """
        // Simple gradient shader
        float3 color = float3(uv.x, uv.y, 0.5 + 0.5 * sin(uniforms.u_time));
        return float4(color, 1.0);
    """
    
    var body: some View {
        MetalCanvasView(fragmentShader: $shaderCode)
            .frame(width: 400, height: 400)
    }
}
```

### Built-in Uniforms

MetalCanvas automatically provides these uniforms to your shaders:

- `u_resolution` - The viewport resolution in pixels (float2)
- `u_time` - Time elapsed since start in seconds (float)
- `u_mouse` - Current mouse/touch position in pixels (float2)
- `u_date` - Current date and time (float4: year, month, day, seconds since midnight)

### Interactive Example

Create an interactive shader that responds to mouse/touch input:

```swift
struct InteractiveView: View {
    @State private var shaderCode: String? = """
        // Distance from mouse position
        float2 mouseUV = uniforms.u_mouse / uniforms.u_resolution;
        float dist = distance(uv, mouseUV);
        
        // Create glow effect
        float glow = exp(-dist * 5.0);
        float3 color = float3(0.5, 0.8, 1.0) * glow;
        
        return float4(color, 1.0);
    """
    
    var body: some View {
        MetalCanvasView(fragmentShader: $shaderCode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Using Textures

Load and display textures in your shaders:

```swift
struct TextureView: View {
    @State private var metalCanvas: MetalCanvas?
    @State private var shaderCode: String? = """
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                     constant FragmentUniforms& uniforms [[buffer(0)]],
                                     texture2d<float, access::sample> myTexture [[texture(0)]]) {
            constexpr sampler textureSampler(mag_filter::linear,
                                           min_filter::linear);
            
            float4 color = myTexture.sample(textureSampler, in.texCoord);
            return color;
        }
    """
    
    var body: some View {
        MetalCanvasView(
            fragmentShader: $shaderCode,
            onCanvasCreated: { canvas in
                metalCanvas = canvas
                loadTexture()
            }
        )
    }
    
    private func loadTexture() {
        Task {
            guard let canvas = metalCanvas,
                  let url = Bundle.main.url(forResource: "image", withExtension: "png") else { return }
            
            let texture = try await canvas.textureManager.loadTexture(from: url, key: "myTexture")
            canvas.setTexture(texture, for: "myTexture")
        }
    }
}
```

### Timer Controls

Control animation playback with built-in timer functions:

```swift
struct AnimationControlView: View {
    @State private var metalCanvas: MetalCanvas?
    @State private var shaderCode: String? = """
        float wave = sin(uniforms.u_time * 2.0);
        float3 color = float3(wave, 0.5, 1.0 - wave);
        return float4(color, 1.0);
    """
    
    var body: some View {
        VStack {
            MetalCanvasView(
                fragmentShader: $shaderCode,
                onCanvasCreated: { canvas in
                    metalCanvas = canvas
                }
            )
            
            HStack {
                Button("Play") {
                    metalCanvas?.play()
                }
                
                Button("Pause") {
                    metalCanvas?.pause()
                }
                
                Button("Reset") {
                    metalCanvas?.reset()
                }
            }
            .padding()
        }
    }
}
```

## Topics

### Essentials

- ``MetalCanvasView``
- ``MetalCanvas``

### Texture Management

- ``TextureManager``

### Timer Control

- ``MetalCanvas/play()``
- ``MetalCanvas/pause()``
- ``MetalCanvas/reset()``
- ``MetalCanvas/toggle()``
- ``MetalCanvas/isTimerPaused``