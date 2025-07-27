# Writing Shaders for MetalCanvas

Learn how to write fragment shaders that work with MetalCanvas.

## Shader Structure

MetalCanvas supports two types of shader input:

### 1. Simple Fragment Code

The easiest way is to provide just the fragment calculation:

```swift
let shader = """
    float3 color = float3(uv.x, uv.y, 0.5);
    return float4(color, 1.0);
"""
```

MetalCanvas automatically wraps this in a proper Metal function with:
- Access to `uv` (texture coordinates)
- Access to `uniforms` (time, resolution, mouse, date)
- Access to `fragCoord` (pixel coordinates)

### 2. Complete Metal Shader

For advanced use cases, provide a complete Metal shader:

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
    float2 uv = in.texCoord;
    float3 color = float3(uv.x, uv.y, 0.5);
    return float4(color, 1.0);
}
```

## Available Variables

### Coordinate Systems

- **`uv`** - Normalized texture coordinates (0.0 to 1.0)
  ```swift
  // Bottom-left is (0,0), top-right is (1,1)
  float2 uv = in.texCoord;
  ```

- **`fragCoord`** - Pixel coordinates
  ```swift
  // Bottom-left is (0,0), top-right is (resolution.x, resolution.y)
  float2 fragCoord = in.position.xy;
  ```

### Built-in Uniforms

- **`uniforms.u_resolution`** - Viewport size in pixels
  ```swift
  float aspectRatio = uniforms.u_resolution.x / uniforms.u_resolution.y;
  ```

- **`uniforms.u_time`** - Time in seconds since start
  ```swift
  float wave = sin(uniforms.u_time * 2.0);
  ```

- **`uniforms.u_mouse`** - Mouse/touch position in pixels
  ```swift
  float2 mouseUV = uniforms.u_mouse / uniforms.u_resolution;
  float dist = distance(uv, mouseUV);
  ```

- **`uniforms.u_date`** - Current date/time
  ```swift
  // x: year, y: month (0-11), z: day, w: seconds since midnight
  float hour = floor(uniforms.u_date.w / 3600.0);
  ```

## Common Shader Patterns

### Color Gradients

```swift
// Linear gradient
float3 color1 = float3(1.0, 0.0, 0.0); // Red
float3 color2 = float3(0.0, 0.0, 1.0); // Blue
float3 color = mix(color1, color2, uv.x);
return float4(color, 1.0);
```

### Circular Patterns

```swift
// Radial gradient from center
float2 center = float2(0.5, 0.5);
float dist = distance(uv, center);
float3 color = float3(1.0 - dist);
return float4(color, 1.0);
```

### Animated Effects

```swift
// Pulsing effect
float pulse = 0.5 + 0.5 * sin(uniforms.u_time * 3.0);
float3 color = float3(pulse, 0.2, 1.0 - pulse);
return float4(color, 1.0);
```

### Mouse Interaction

```swift
// Follow mouse with glow
float2 mouseUV = uniforms.u_mouse / uniforms.u_resolution;
float dist = distance(uv, mouseUV);
float glow = exp(-dist * 10.0);
float3 color = float3(glow) * float3(1.0, 0.5, 0.0);
return float4(color, 1.0);
```

## Using Textures

When using textures, you need to provide a complete Metal shader:

```metal
fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant FragmentUniforms& uniforms [[buffer(0)]],
                             texture2d<float, access::sample> myTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                    min_filter::linear,
                                    address::clamp_to_edge);
    
    float2 uv = in.texCoord;
    
    // Sample the texture
    float4 texColor = myTexture.sample(textureSampler, uv);
    
    // Apply effects
    float brightness = 0.5 + 0.5 * sin(uniforms.u_time);
    texColor.rgb *= brightness;
    
    return texColor;
}
```

## Performance Tips

1. **Minimize Texture Samples** - Texture sampling is expensive
2. **Use Built-in Functions** - Metal's built-in functions are optimized
3. **Avoid Branching** - Use step(), smoothstep(), and mix() instead of if/else
4. **Precompute Constants** - Calculate constant values outside the shader when possible

## Debugging Shaders

### Visualize Values

```swift
// Debug UV coordinates
return float4(uv.x, uv.y, 0.0, 1.0);

// Debug time
float t = fract(uniforms.u_time);
return float4(t, t, t, 1.0);

// Debug mouse position
float2 mouseUV = uniforms.u_mouse / uniforms.u_resolution;
float nearMouse = 1.0 - step(0.1, distance(uv, mouseUV));
return float4(nearMouse, 0.0, 0.0, 1.0);
```

### Common Issues

1. **Black Screen** - Check that your shader returns a valid float4
2. **Compilation Errors** - Check the console for Metal compiler errors
3. **Unexpected Colors** - Ensure color values are in 0.0-1.0 range