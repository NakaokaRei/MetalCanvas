import SwiftUI
import MetalKit

#if os(macOS)
import AppKit

/// Custom MTKView subclass for macOS that tracks mouse movement
class MouseTrackingMTKView: MTKView {
    var mouseMovedHandler: ((CGPoint) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTrackingArea()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupTrackingArea()
    }
    
    private func setupTrackingArea() {
        // Remove existing tracking areas
        trackingAreas.forEach { removeTrackingArea($0) }
        
        // Add new tracking area
        let options: NSTrackingArea.Options = [.activeInKeyWindow, .mouseMoved, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        
        // Accept mouse moved events
        window?.acceptsMouseMovedEvents = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        // Get the drawable size to account for Retina displays
        let drawableSize = self.drawableSize
        let viewSize = self.bounds.size
        
        // Scale the coordinates to match the drawable size
        let scaleX = drawableSize.width / viewSize.width
        let scaleY = drawableSize.height / viewSize.height
        
        // Flip Y coordinate and scale - macOS AppKit uses top-left origin, Metal uses bottom-left
        let scaledLocation = CGPoint(
            x: location.x * scaleX,
            y: (viewSize.height - location.y) * scaleY
        )
        mouseMovedHandler?(scaledLocation)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let drawableSize = self.drawableSize
        let viewSize = self.bounds.size
        let scaleX = drawableSize.width / viewSize.width
        let scaleY = drawableSize.height / viewSize.height
        let scaledLocation = CGPoint(
            x: location.x * scaleX,
            y: (viewSize.height - location.y) * scaleY
        )
        mouseMovedHandler?(scaledLocation)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let drawableSize = self.drawableSize
        let viewSize = self.bounds.size
        let scaleX = drawableSize.width / viewSize.width
        let scaleY = drawableSize.height / viewSize.height
        let scaledLocation = CGPoint(
            x: location.x * scaleX,
            y: (viewSize.height - location.y) * scaleY
        )
        mouseMovedHandler?(scaledLocation)
    }
}

/// A SwiftUI view that displays a MetalCanvas for rendering shaders on macOS.
///
/// This view provides a SwiftUI wrapper around MetalCanvas, making it easy to
/// integrate shader rendering into your SwiftUI app.
///
/// ## Example Usage
/// ```swift
/// MetalCanvasView(
///     fragmentShader: $shaderCode,
///     onShaderError: { error in
///         print("Shader error: \(error)")
///     }
/// )
/// ```
public struct MetalCanvasView: NSViewRepresentable {
    @Binding var fragmentShader: String?
    @Binding var vertexShader: String?
    let backgroundColor: Color
    let onShaderError: ((Error) -> Void)?
    let onCanvasCreated: ((MetalCanvas) -> Void)?
    
    /// Creates a new MetalCanvasView.
    ///
    /// - Parameters:
    ///   - fragmentShader: A binding to the fragment shader source code.
    ///   - vertexShader: A binding to the vertex shader source code (optional).
    ///   - backgroundColor: The background color of the canvas.
    ///   - onShaderError: A closure called when a shader compilation error occurs.
    ///   - onCanvasCreated: A closure called when the MetalCanvas instance is created.
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
        let mtkView = MouseTrackingMTKView()
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
        
        // Set up mouse tracking
        let coordinator = context.coordinator
        mtkView.mouseMovedHandler = { location in
            coordinator.metalCanvas?.mouse = SIMD2<Float>(Float(location.x), Float(location.y))
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
        
        // Update mouse handler if the view is MouseTrackingMTKView
        if let trackingView = nsView as? MouseTrackingMTKView {
            let coordinator = context.coordinator
            trackingView.mouseMovedHandler = { location in
                coordinator.metalCanvas?.mouse = SIMD2<Float>(Float(location.x), Float(location.y))
            }
        }
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

/// Custom MTKView subclass for iOS that tracks touch movement
class TouchTrackingMTKView: MTKView {
    var touchMovedHandler: ((CGPoint) -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            // Get the drawable size to account for Retina displays
            let drawableSize = self.drawableSize
            let viewSize = self.bounds.size
            
            // Scale the coordinates to match the drawable size
            let scaleX = drawableSize.width / viewSize.width
            let scaleY = drawableSize.height / viewSize.height
            
            // Scale but don't flip Y coordinate for iOS
            let scaledLocation = CGPoint(
                x: location.x * scaleX,
                y: location.y * scaleY
            )
            touchMovedHandler?(scaledLocation)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let drawableSize = self.drawableSize
            let viewSize = self.bounds.size
            let scaleX = drawableSize.width / viewSize.width
            let scaleY = drawableSize.height / viewSize.height
            let scaledLocation = CGPoint(
                x: location.x * scaleX,
                y: location.y * scaleY
            )
            touchMovedHandler?(scaledLocation)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            let drawableSize = self.drawableSize
            let viewSize = self.bounds.size
            let scaleX = drawableSize.width / viewSize.width
            let scaleY = drawableSize.height / viewSize.height
            let scaledLocation = CGPoint(
                x: location.x * scaleX,
                y: location.y * scaleY
            )
            touchMovedHandler?(scaledLocation)
        }
    }
}

/// A SwiftUI view that displays a MetalCanvas for rendering shaders on iOS.
///
/// This view provides a SwiftUI wrapper around MetalCanvas, making it easy to
/// integrate shader rendering into your SwiftUI app.
///
/// ## Example Usage
/// ```swift
/// MetalCanvasView(
///     fragmentShader: $shaderCode,
///     onShaderError: { error in
///         print("Shader error: \(error)")
///     }
/// )
/// ```
public struct MetalCanvasView: UIViewRepresentable {
    @Binding var fragmentShader: String?
    @Binding var vertexShader: String?
    let backgroundColor: Color
    let onShaderError: ((Error) -> Void)?
    let onCanvasCreated: ((MetalCanvas) -> Void)?
    
    /// Creates a new MetalCanvasView.
    ///
    /// - Parameters:
    ///   - fragmentShader: A binding to the fragment shader source code.
    ///   - vertexShader: A binding to the vertex shader source code (optional).
    ///   - backgroundColor: The background color of the canvas.
    ///   - onShaderError: A closure called when a shader compilation error occurs.
    ///   - onCanvasCreated: A closure called when the MetalCanvas instance is created.
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
        let mtkView = TouchTrackingMTKView()
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
        
        // Set up touch tracking
        let coordinator = context.coordinator
        mtkView.touchMovedHandler = { location in
            coordinator.metalCanvas?.mouse = SIMD2<Float>(Float(location.x), Float(location.y))
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
        
        // Update touch handler if the view is TouchTrackingMTKView
        if let trackingView = uiView as? TouchTrackingMTKView {
            let coordinator = context.coordinator
            trackingView.touchMovedHandler = { location in
                coordinator.metalCanvas?.mouse = SIMD2<Float>(Float(location.x), Float(location.y))
            }
        }
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