# Getting Started with MetalCanvas

Learn how to integrate MetalCanvas into your SwiftUI app and create your first shader.

## Installation

Add MetalCanvas to your project using Swift Package Manager:

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/NakaokaRei/MetalCanvas`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/NakaokaRei/MetalCanvas", from: "0.1.0")
]
```

## Your First Shader

### Step 1: Import MetalCanvas

```swift
import MetalCanvas
import SwiftUI
```

### Step 2: Create a Simple View

```swift
struct MyShaderView: View {
    @State private var fragmentShader: String? = """
        // This shader creates a colorful gradient
        float3 color = float3(uv.x, uv.y, 0.5);
        return float4(color, 1.0);
    """
    
    var body: some View {
        MetalCanvasView(fragmentShader: $fragmentShader)
    }
}
```

### Step 3: Understanding the Shader Code

In the shader code:
- `uv` contains the texture coordinates (0.0 to 1.0)
- `uniforms` provides access to built-in values like time and resolution
- The shader must return a `float4` representing RGBA color values

## Animated Shaders

Add animation using the `u_time` uniform:

```swift
@State private var animatedShader: String? = """
    // Create animated waves
    float wave = sin(uv.y * 10.0 + uniforms.u_time * 2.0);
    float3 color = float3(wave, 0.5, 1.0 - wave);
    return float4(color, 1.0);
"""
```

## Complete Example App

Here's a complete example app that demonstrates basic features:

```swift
import SwiftUI
import MetalCanvas

@main
struct MetalCanvasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedExample = 0
    @State private var fragmentShader: String?
    
    let examples = [
        ("Gradient", """
            float3 color = float3(uv.x, uv.y, 0.5 + 0.5 * sin(uniforms.u_time));
            return float4(color, 1.0);
        """),
        ("Circles", """
            float2 center = float2(0.5, 0.5);
            float dist = distance(uv, center);
            float circle = 1.0 - step(0.3, dist);
            float3 color = float3(circle) * float3(0.3, 0.6, 1.0);
            return float4(color, 1.0);
        """),
        ("Plasma", """
            float v1 = sin(uv.x * 10.0 + uniforms.u_time);
            float v2 = sin(10.0 * (uv.x * sin(uniforms.u_time / 2.0) + 
                          uv.y * cos(uniforms.u_time / 3.0)) + uniforms.u_time);
            float v = v1 + v2;
            float3 color = float3(sin(v), sin(v + 2.0), sin(v + 4.0));
            color = 0.5 + 0.5 * color;
            return float4(color, 1.0);
        """)
    ]
    
    var body: some View {
        VStack {
            // Shader selection
            Picker("Shader", selection: $selectedExample) {
                ForEach(0..<examples.count, id: \.self) { index in
                    Text(examples[index].0).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Metal canvas view
            MetalCanvasView(fragmentShader: $fragmentShader)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .onAppear {
            fragmentShader = examples[selectedExample].1
        }
        .onChange(of: selectedExample) { newValue in
            fragmentShader = examples[newValue].1
        }
    }
}
```

## Next Steps

- Explore the ``MetalCanvas`` class for advanced features
- Learn about ``TextureManager`` for loading images
- Check out the example projects for more complex shaders