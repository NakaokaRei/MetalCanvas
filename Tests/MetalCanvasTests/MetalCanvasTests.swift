import Testing
@testable import MetalCanvas
import Metal

@Test("MetalCanvas initialization")
func testMetalCanvasInitialization() throws {
    let canvas = MetalCanvas()
    #expect(canvas != nil)
    #expect(canvas?.device != nil)
    #expect(canvas?.commandQueue != nil)
}

@Test("Uniforms initialization")
func testUniformsInitialization() throws {
    let uniforms = Uniforms()
    
    #expect(uniforms.get("u_resolution") != nil)
    #expect(uniforms.get("u_time") != nil)
    #expect(uniforms.get("u_mouse") != nil)
    #expect(uniforms.get("u_date") != nil)
}

@Test("Uniforms update")
func testUniformsUpdate() throws {
    let uniforms = Uniforms()
    
    uniforms.update("u_time", value: Float(1.5))
    
    if let timeUniform = uniforms.get("u_time"),
       let value = timeUniform.value as? Float {
        #expect(abs(value - 1.5) < 0.001)
    } else {
        Issue.record("Failed to update time uniform")
    }
}

@Test("Canvas timer functionality")
func testCanvasTimer() throws {
    let timer = CanvasTimer()
    
    #expect(!timer.isPaused)
    #expect(abs(timer.current - 0) < 0.001)
    
    timer.pause()
    #expect(timer.isPaused)
    
    timer.play()
    #expect(!timer.isPaused)
}

@Test("Texture manager operations")
func testTextureManager() throws {
    guard let device = MTLCreateSystemDefaultDevice() else {
        throw SkipTest("Metal is not supported on this device")
    }
    
    let textureManager = TextureManager(device: device)
    
    let texture = textureManager.createTexture(width: 256, height: 256, key: "test_texture")
    #expect(texture != nil)
    
    let retrievedTexture = textureManager.getTexture(for: "test_texture")
    #expect(retrievedTexture != nil)
    #expect(texture === retrievedTexture, "Retrieved texture should be the same instance")
    
    textureManager.removeTexture(for: "test_texture")
    #expect(textureManager.getTexture(for: "test_texture") == nil)
}

struct SkipTest: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}