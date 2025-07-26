import Foundation
import Metal
import MetalKit
import simd

public class MetalCanvas: NSObject {
    
    public var device: MTLDevice
    public var commandQueue: MTLCommandQueue
    
    private var renderPipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    
    private var startTime: Date
    private var timer: CanvasTimer
    
    public var backgroundColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var resolution: SIMD2<Float> = .zero
    public var mouse: SIMD2<Float> = .zero
    
    private var uniforms = Uniforms()
    private var textures = [String: MTLTexture]()
    
    public var onShaderError: ((Error) -> Void)?
    
    public var fragmentShaderSource: String? {
        didSet {
            print("MetalCanvas: fragmentShaderSource didSet - value: \(fragmentShaderSource != nil)")
            if fragmentShaderSource != nil {
                loadShaders()
            }
        }
    }
    
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
        
        super.init()
        
        setupVertexBuffer()
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
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateUniforms(size: CGSize) {
        resolution = SIMD2<Float>(Float(size.width), Float(size.height))
        
        let time = Float(Date().timeIntervalSince(startTime))
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
    
    public func setTexture(_ texture: MTLTexture, for key: String) {
        textures[key] = texture
    }
    
    public func pause() {
        timer.pause()
    }
    
    public func play() {
        timer.play()
    }
    
    public func toggle() {
        timer.toggle()
    }
}

fileprivate struct FragmentUniforms {
    var u_resolution: SIMD2<Float>
    var u_time: Float
    var u_mouse: SIMD2<Float>
    var u_date: SIMD4<Float>
}