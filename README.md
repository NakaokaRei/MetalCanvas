# MetalCanvas

MetalCanvas is a Swift library for rendering Metal shaders on macOS and iOS, inspired by [glsl-canvas](https://github.com/actarian/glsl-canvas).

https://github.com/user-attachments/assets/3d06bc45-9690-4a52-9e82-7d7bb3ab7daf


## Features

- Easy-to-use Metal shader rendering
- Built-in uniforms (time, resolution, mouse, date)
- Texture support
- SwiftUI integration
- Timer controls (play, pause, toggle)
- Cross-platform (macOS 14+, iOS 17+)

## Installation

### Swift Package Manager

#### Xcode

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/NakaokaRei/MetalCanvas.git`
3. Click **Add Package** and select the version

#### Package.swift

Add MetalCanvas to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/NakaokaRei/MetalCanvas.git", from: "1.0.0")
]
```

Then add `MetalCanvas` to your target's dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["MetalCanvas"]
    )
]
```

## Usage

### Basic Example

```swift
import SwiftUI
import MetalCanvas

struct ContentView: View {
    @State private var fragmentShader: String? = """
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
    
    var body: some View {
        MetalCanvasView(fragmentShader: $fragmentShader)
            .frame(width: 400, height: 400)
    }
}
```

### Available Uniforms

- `u_resolution` - Viewport resolution (width, height) in pixels
- `u_time` - Time in seconds since render started
- `u_mouse` - Mouse position in pixels
- `u_date` - Current date (year, month, day, seconds since midnight)

### Creating Metal Shaders

MetalCanvas expects shaders written in Metal Shading Language. The fragment shader should include:

```metal
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
    // Your shader code here
    return float4(color, 1.0);
}
```

## Examples

Check out the example apps in the `Example` directory:

### macOS Example
Located in `Example/MetalCanvasExample-macOS/`:
- Interactive shader editor with live preview
- Built-in shader examples (gradient, circles, plasma, mandelbrot, waves, voronoi)
- Play/pause controls
- Code editor with syntax highlighting

### iOS Example
Located in `Example/MetalCanvasExample-iOS/`:
- Shader gallery with segmented picker
- Same built-in shader examples as macOS
- Optimized for touch interface

To run the examples:
1. Open `Example/MetalCanvasExamples.xcworkspace`
2. Select either `MetalCanvasExample` (macOS) or `MetalCanvasExample-iOS` scheme
3. Build and run

## Requirements

- macOS 14.0+ / iOS 17.0+
- Swift 5.9+

## License

MIT License
