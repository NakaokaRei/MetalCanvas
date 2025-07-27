import SwiftUI
import MetalKit

#if os(macOS)
import AppKit

public struct MetalCanvasView: NSViewRepresentable {
    @Binding var fragmentShader: String?
    @Binding var vertexShader: String?
    let backgroundColor: Color
    let onShaderError: ((Error) -> Void)?
    let onCanvasCreated: ((MetalCanvas) -> Void)?
    
    public init(fragmentShader: Binding<String?>, 
                vertexShader: Binding<String?> = .constant(nil),
                backgroundColor: Color = .black,
                onShaderError: ((Error) -> Void)? = nil,
                onCanvasCreated: ((MetalCanvas) -> Void)? = nil) {
        self._fragmentShader = fragmentShader
        self._vertexShader = vertexShader
        self.backgroundColor = backgroundColor
        self.onShaderError = onShaderError
        self.onCanvasCreated = onCanvasCreated
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = backgroundColor.metalClearColor
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        
        if let device = mtkView.device {
            context.coordinator.metalCanvas = MetalCanvas(metalDevice: device)
            context.coordinator.metalCanvas?.onShaderError = onShaderError
            print("MetalCanvasView: Setting fragment shader - \(fragmentShader != nil)")
            context.coordinator.metalCanvas?.fragmentShaderSource = fragmentShader
            context.coordinator.metalCanvas?.vertexShaderSource = vertexShader
            context.coordinator.metalCanvas?.backgroundColor = backgroundColor.metalClearColor
            
            // Call onCanvasCreated callback
            if let canvas = context.coordinator.metalCanvas {
                onCanvasCreated?(canvas)
            }
        }
        
        // Set delegate after MetalCanvas is configured
        mtkView.delegate = context.coordinator
        mtkView.isPaused = false
        
        return mtkView
    }
    
    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.metalCanvas?.fragmentShaderSource = fragmentShader
        context.coordinator.metalCanvas?.vertexShaderSource = vertexShader
        context.coordinator.metalCanvas?.backgroundColor = backgroundColor.metalClearColor
    }
    
    public class Coordinator: NSObject, MTKViewDelegate {
        var metalCanvas: MetalCanvas?
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }
        
        public func draw(in view: MTKView) {
            metalCanvas?.render(to: view)
        }
    }
}

#else
import UIKit

public struct MetalCanvasView: UIViewRepresentable {
    @Binding var fragmentShader: String?
    @Binding var vertexShader: String?
    let backgroundColor: Color
    let onShaderError: ((Error) -> Void)?
    let onCanvasCreated: ((MetalCanvas) -> Void)?
    
    public init(fragmentShader: Binding<String?>, 
                vertexShader: Binding<String?> = .constant(nil),
                backgroundColor: Color = .black,
                onShaderError: ((Error) -> Void)? = nil,
                onCanvasCreated: ((MetalCanvas) -> Void)? = nil) {
        self._fragmentShader = fragmentShader
        self._vertexShader = vertexShader
        self.backgroundColor = backgroundColor
        self.onShaderError = onShaderError
        self.onCanvasCreated = onCanvasCreated
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = backgroundColor.metalClearColor
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        
        if let device = mtkView.device {
            context.coordinator.metalCanvas = MetalCanvas(metalDevice: device)
            context.coordinator.metalCanvas?.onShaderError = onShaderError
            print("MetalCanvasView: Setting fragment shader - \(fragmentShader != nil)")
            context.coordinator.metalCanvas?.fragmentShaderSource = fragmentShader
            context.coordinator.metalCanvas?.vertexShaderSource = vertexShader
            context.coordinator.metalCanvas?.backgroundColor = backgroundColor.metalClearColor
            
            // Call onCanvasCreated callback
            if let canvas = context.coordinator.metalCanvas {
                onCanvasCreated?(canvas)
            }
        }
        
        // Set delegate after MetalCanvas is configured
        mtkView.delegate = context.coordinator
        mtkView.isPaused = false
        
        return mtkView
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.metalCanvas?.fragmentShaderSource = fragmentShader
        context.coordinator.metalCanvas?.vertexShaderSource = vertexShader
        context.coordinator.metalCanvas?.backgroundColor = backgroundColor.metalClearColor
    }
    
    public class Coordinator: NSObject, MTKViewDelegate {
        var metalCanvas: MetalCanvas?
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }
        
        public func draw(in view: MTKView) {
            metalCanvas?.render(to: view)
        }
    }
}
#endif

extension Color {
    var metalClearColor: MTLClearColor {
        #if os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return MTLClearColor(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }
}