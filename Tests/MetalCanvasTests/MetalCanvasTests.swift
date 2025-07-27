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