import XCTest
@testable import MetalCanvas

final class MetalCanvasTests: XCTestCase {
    
    func testMetalCanvasInitialization() throws {
        let canvas = MetalCanvas()
        XCTAssertNotNil(canvas)
        XCTAssertNotNil(canvas?.device)
        XCTAssertNotNil(canvas?.commandQueue)
    }
    
    func testUniformsInitialization() throws {
        let uniforms = Uniforms()
        
        XCTAssertNotNil(uniforms.get("u_resolution"))
        XCTAssertNotNil(uniforms.get("u_time"))
        XCTAssertNotNil(uniforms.get("u_mouse"))
        XCTAssertNotNil(uniforms.get("u_date"))
    }
    
    func testUniformsUpdate() throws {
        let uniforms = Uniforms()
        
        uniforms.update("u_time", value: Float(1.5))
        
        if let timeUniform = uniforms.get("u_time"),
           let value = timeUniform.value as? Float {
            XCTAssertEqual(value, 1.5, accuracy: 0.001)
        } else {
            XCTFail("Failed to update time uniform")
        }
    }
    
    func testCanvasTimer() throws {
        let timer = CanvasTimer()
        
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.current, 0, accuracy: 0.001)
        
        timer.pause()
        XCTAssertTrue(timer.isPaused)
        
        timer.play()
        XCTAssertFalse(timer.isPaused)
    }
    
    func testTextureManager() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            XCTSkip("Metal is not supported on this device")
            return
        }
        
        let textureManager = TextureManager(device: device)
        
        let texture = textureManager.createTexture(width: 256, height: 256, key: "test_texture")
        XCTAssertNotNil(texture)
        
        let retrievedTexture = textureManager.getTexture(for: "test_texture")
        XCTAssertNotNil(retrievedTexture)
        XCTAssertEqual(texture, retrievedTexture)
        
        textureManager.removeTexture(for: "test_texture")
        XCTAssertNil(textureManager.getTexture(for: "test_texture"))
    }
}