import Foundation
import Metal
import MetalKit
import simd

/// A Metal-based canvas for rendering fragment shaders with built-in uniforms.
///
/// MetalCanvas provides an easy-to-use interface for rendering Metal shaders,
/// similar to GLSL canvas tools. It automatically provides common uniforms like
/// time, resolution, mouse position, and date to your shaders.
///
/// ## Example Usage
/// ```swift
/// let canvas = MetalCanvas(metalDevice: device)
/// canvas.fragmentShaderSource = myShaderCode
/// canvas.render(to: mtkView)
/// ```
public class MetalCanvas: NSObject {
    
    /// The Metal device used for rendering.
    public var device: MTLDevice
    
    /// The command queue for encoding rendering commands.
    public var commandQueue: MTLCommandQueue
    
    private var renderPipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    
    private var startTime: Date
    private var timer: CanvasTimer
    
    /// The texture manager for loading and managing textures.
    public let textureManager: TextureManager
    
    /// The background color used when clearing the canvas.
    public var backgroundColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    
    /// The current resolution of the rendering surface in pixels.
    public var resolution: SIMD2<Float> = .zero
    
    /// The current mouse position in pixels.
    public var mouse: SIMD2<Float> = .zero
    
    private var textures = [String: MTLTexture]()
    
    /// A closure called when a shader compilation error occurs.
    public var onShaderError: ((Error) -> Void)?
    
    /// The Metal fragment shader source code.
    ///
    /// When set, the shader is automatically compiled and the render pipeline is updated.
    /// The shader should include the required uniform structures.
    public var fragmentShaderSource: String? {
        didSet {
            print("MetalCanvas: fragmentShaderSource didSet - value: \(fragmentShaderSource != nil)")
            if fragmentShaderSource != nil {
                loadShaders()
            }
        }
    }
    
    /// The Metal vertex shader source code.
    ///
    /// If not provided, a default vertex shader is used that renders a full-screen quad.
    public var vertexShaderSource: String?
    
    private var defaultVertexShader = """
    #include <metal_stdlib>
    using namespace metal;
    
    struct VertexIn {
        packed_float2 position;
        packed_float2 texCoord;
    };
    
    struct VertexOut {
        float4 position [[position]];
        float2 texCoord;
    };
    
    vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                                 constant VertexIn* vertices [[buffer(0)]]) {
        VertexOut out;
        out.position = float4(vertices[vertexID].position, 0.0, 1.0);
        out.texCoord = vertices[vertexID].texCoord;
        return out;
    }
    """
    
    /// Initializes a new MetalCanvas instance.
    ///
    /// - Parameter metalDevice: The Metal device to use for rendering. If nil, the system default device is used.
    /// - Returns: A configured MetalCanvas instance, or nil if initialization fails.
    public init?(metalDevice: MTLDevice? = nil) {
        guard let device = metalDevice ?? MTLCreateSystemDefaultDevice() else {
            return nil
        }
        
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.commandQueue = commandQueue
        self.startTime = Date()
        self.timer = CanvasTimer()
        self.textureManager = TextureManager(device: device)
        
        super.init()
        
        setupVertexBuffer()
        createDefaultTexture()
    }
    
    private func setupVertexBuffer() {
        let vertices: [Float] = [
            -1.0, -1.0,  0.0, 1.0,
             1.0, -1.0,  1.0, 1.0,
            -1.0,  1.0,  0.0, 0.0,
             1.0,  1.0,  1.0, 0.0,
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Float>.stride,
                                         options: [])
    }
    
    private func createDefaultTexture() {
        // Create a 1x1 white texture as default
        let descriptor = MTLTextureDescriptor()
        descriptor.width = 1
        descriptor.height = 1
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else { return }
        
        let white: [UInt8] = [255, 255, 255, 255]
        texture.replace(region: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                         size: MTLSize(width: 1, height: 1, depth: 1)),
                       mipmapLevel: 0,
                       withBytes: white,
                       bytesPerRow: 4)
        
        textures["_default"] = texture
    }
    
    private func loadShaders() {
        guard let fragmentSource = fragmentShaderSource else { 
            print("MetalCanvas: No fragment shader source")
            return 
        }
        
        let vertexSource = vertexShaderSource ?? defaultVertexShader
        
        let metalFragmentSource = prepareMetalShader(fragmentSource)
        print("MetalCanvas: Loading shaders...")
        
        do {
            // Check if the fragment shader is already a complete Metal shader
            let combinedSource: String
            if metalFragmentSource.contains("vertex_main") {
                // Complete Metal shader, use as-is
                combinedSource = metalFragmentSource
                print("MetalCanvas: Using complete Metal shader")
            } else if metalFragmentSource.contains("struct VertexOut") {
                // Fragment shader already has VertexOut definition, extract it and combine
                // Remove the duplicate VertexOut struct from vertex shader
                let vertexWithoutVertexOut = vertexSource
                    .replacingOccurrences(of: """
                    struct VertexOut {
                        float4 position [[position]];
                        float2 texCoord;
                    };
                    
                    """, with: "")
                combinedSource = """
                \(metalFragmentSource)
                
                \(vertexWithoutVertexOut)
                """
                print("MetalCanvas: Combining with vertex shader (VertexOut already defined)")
            } else {
                // Fragment-only shader, combine with default vertex shader
                combinedSource = """
                \(vertexSource)
                
                \(metalFragmentSource)
                """
                print("MetalCanvas: Combining with default vertex shader")
            }
            
            let library = try device.makeLibrary(source: combinedSource, options: nil)
            
            let vertexFunction = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("MetalCanvas: Shaders loaded successfully")
            
        } catch {
            print("Error creating render pipeline: \(error)")
            onShaderError?(error)
        }
    }
    
    private func prepareMetalShader(_ shader: String) -> String {
        // If the shader already contains Metal headers, it's already a complete Metal shader
        if shader.contains("#include <metal_stdlib>") {
            return shader
        }
        
        // Otherwise, wrap it in a basic Metal fragment function
        return """
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
            
            \(shader)
            
            return float4(1.0); // Default return if not provided
        }
        """
    }
    
    /// Renders the current shader to the specified MTKView.
    ///
    /// This method is typically called from an MTKViewDelegate's draw method.
    /// It updates uniforms, binds textures, and executes the fragment shader.
    ///
    /// - Parameter view: The MTKView to render to.
    public func render(to view: MTKView) {
        guard let renderPipelineState = renderPipelineState,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("MetalCanvas: Missing render requirements - pipeline: \(renderPipelineState != nil), drawable: \(view.currentDrawable != nil), descriptor: \(view.currentRenderPassDescriptor != nil)")
            return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = backgroundColor
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        timer.update()
        updateUniforms(size: view.drawableSize)
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        if let uniformBuffer = uniformBuffer {
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        }
        
        // Bind textures - always bind at least the default texture
        var textureToUse: MTLTexture? = textures["_default"]
        
        // Use a specific texture if available (not the default)
        for (key, texture) in textures where key != "_default" {
            textureToUse = texture
            break
        }
        
        if let texture = textureToUse {
            renderEncoder.setFragmentTexture(texture, index: 0)
        }
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateUniforms(size: CGSize) {
        resolution = SIMD2<Float>(Float(size.width), Float(size.height))
        
        let time = Float(timer.current)
        let date = Date()
        let calendar = Calendar.current
        
        var uniformData = FragmentUniforms(
            u_resolution: resolution,
            u_time: time,
            u_mouse: mouse,
            u_date: SIMD4<Float>(
                Float(calendar.component(.year, from: date)),
                Float(calendar.component(.month, from: date) - 1),
                Float(calendar.component(.day, from: date)),
                Float(calendar.component(.hour, from: date) * 3600 +
                      calendar.component(.minute, from: date) * 60 +
                      calendar.component(.second, from: date)) +
                      Float(calendar.component(.nanosecond, from: date)) * 1e-9
            )
        )
        
        uniformBuffer = device.makeBuffer(bytes: &uniformData,
                                         length: MemoryLayout<FragmentUniforms>.stride,
                                         options: [])
    }
    
    /// Sets a texture for use in shaders.
    ///
    /// - Parameters:
    ///   - texture: The Metal texture to set.
    ///   - key: A unique identifier for the texture.
    public func setTexture(_ texture: MTLTexture, for key: String) {
        textures[key] = texture
    }
    
    /// Pauses the animation timer.
    ///
    /// When paused, the `u_time` uniform stops incrementing.
    public func pause() {
        timer.pause()
    }
    
    /// Resumes the animation timer.
    ///
    /// When playing, the `u_time` uniform continues incrementing.
    public func play() {
        timer.play()
    }
    
    /// Toggles the animation timer between paused and playing states.
    public func toggle() {
        timer.toggle()
    }
    
    /// Resets the animation timer to zero.
    ///
    /// This resets the `u_time` uniform back to 0.0.
    public func reset() {
        timer.reset()
    }
    
    /// Returns whether the animation timer is currently paused.
    public var isTimerPaused: Bool {
        return timer.isPaused
    }
}

fileprivate struct FragmentUniforms {
    var u_resolution: SIMD2<Float>
    var u_time: Float
    var u_mouse: SIMD2<Float>
    var u_date: SIMD4<Float>
}