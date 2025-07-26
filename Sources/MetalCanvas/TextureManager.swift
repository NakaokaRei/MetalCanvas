import Foundation
import Metal
import MetalKit

public enum TextureError: Error {
    case invalidURL
    case loadingFailed
    case textureCreationFailed
}

public class TextureManager {
    private let device: MTLDevice
    private var textures: [String: MTLTexture] = [:]
    private let textureLoader: MTKTextureLoader
    
    public init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
    }
    
    public func loadTexture(from url: URL, key: String) async throws -> MTLTexture {
        if let existingTexture = textures[key] {
            return existingTexture
        }
        
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .generateMipmaps: true,
            .SRGB: false
        ]
        
        do {
            let texture = try await textureLoader.newTexture(URL: url, options: options)
            textures[key] = texture
            return texture
        } catch {
            throw TextureError.loadingFailed
        }
    }
    
    public func loadTexture(from data: Data, key: String) async throws -> MTLTexture {
        if let existingTexture = textures[key] {
            return existingTexture
        }
        
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .generateMipmaps: true,
            .SRGB: false
        ]
        
        do {
            let texture = try await textureLoader.newTexture(data: data, options: options)
            textures[key] = texture
            return texture
        } catch {
            throw TextureError.loadingFailed
        }
    }
    
    public func createTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .rgba8Unorm, key: String) -> MTLTexture? {
        if let existingTexture = textures[key] {
            return existingTexture
        }
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = width
        descriptor.height = height
        descriptor.pixelFormat = pixelFormat
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        textures[key] = texture
        return texture
    }
    
    public func getTexture(for key: String) -> MTLTexture? {
        return textures[key]
    }
    
    public func removeTexture(for key: String) {
        textures.removeValue(forKey: key)
    }
    
    public func removeAllTextures() {
        textures.removeAll()
    }
}