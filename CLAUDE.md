# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MetalCanvas is a Swift library that provides an easy-to-use interface for rendering Metal shaders on macOS and iOS, inspired by glsl-canvas. It offers SwiftUI integration and automatic shader compilation with built-in uniforms.

## Build Commands

```bash
# Build the Swift Package
swift build

# Run tests
swift test

# Build and run the Example app (Swift Package executable)
swift run MetalCanvasExample

# Build the macOS Example app using Xcode
cd Example
xcodebuild -workspace MetalCanvasExamples.xcworkspace -scheme MetalCanvasExample -configuration Debug build

# Build the iOS Example app using Xcode
cd Example
xcodebuild -workspace MetalCanvasExamples.xcworkspace -scheme MetalCanvasExample-iOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build

# Open the Example workspace in Xcode
open Example/MetalCanvasExamples.xcworkspace
```

## Architecture

### Core Components

1. **MetalCanvas.swift** - Main rendering engine that handles:
   - Shader compilation and pipeline creation
   - Automatic vertex/fragment shader combination
   - Render loop management
   - Built-in uniform updates (time, resolution, mouse, date)

2. **MetalCanvasView.swift** - SwiftUI integration layer:
   - Provides NSViewRepresentable (macOS) and UIViewRepresentable (iOS)
   - Manages MTKView lifecycle and delegate
   - Handles shader source binding

3. **Shader Loading Strategy**:
   - Accepts complete Metal shaders or fragment-only shaders
   - Automatically provides default vertex shader when needed
   - Handles struct definition conflicts during shader combination
   - Uses `prepareMetalShader()` to wrap non-Metal shader code

### Shader Requirements

Fragment shaders must define these structures:
```metal
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
```

### Key Implementation Details

- **Vertex Buffer**: Uses a simple quad (-1 to 1 in NDC) with texture coordinates
- **Shader Combination**: The `loadShaders()` method intelligently combines vertex and fragment shaders, avoiding duplicate struct definitions
- **Uniform Updates**: Automatically updates built-in uniforms every frame in the render loop
- **Timer Management**: CanvasTimer handles animation timing with play/pause functionality

## Development Workflow

When adding new features:
1. Metal shaders go in Example/Shared/ShaderExamples.swift (shared between macOS and iOS)
2. Core rendering changes affect Sources/MetalCanvas/MetalCanvas.swift
3. UI integration changes go in Sources/MetalCanvas/MetalCanvasView.swift
4. Example apps are in Example/MetalCanvasExample-macOS and Example/MetalCanvasExample-iOS

## Common Issues

- **Shader compilation errors**: Check for duplicate struct definitions when combining shaders
- **Pipeline creation failures**: Ensure vertex_main and fragment_main functions are properly defined
- **Rendering not starting**: Verify MTKView delegate is set after MetalCanvas initialization