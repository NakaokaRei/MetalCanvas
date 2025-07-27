import Foundation
import Metal
import MetalKit

/// Errors that can occur during texture operations.
public enum TextureError: Error {
    /// The provided URL is invalid.
    case invalidURL
    /// Failed to load the texture data.
    case loadingFailed
    /// Failed to create the Metal texture.
    case textureCreationFailed
}

/// Manages texture loading and caching for MetalCanvas.
///
/// TextureManager provides convenient methods to load textures from URLs or data,
/// create procedural textures, and manage texture resources.
public class TextureManager {
    private let device: MTLDevice
    private var textures: [String: MTLTexture] = [:]
    private let textureLoader: MTKTextureLoader
    
    /// Initializes a new TextureManager.
    ///
    /// - Parameter device: The Metal device to use for creating textures.
    public init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
    }
    
    /// Loads a texture from a URL asynchronously.
    ///
    /// If a texture with the same key already exists, it returns the cached texture.
    ///
    /// - Parameters:
    ///   - url: The URL of the image file to load.
    ///   - key: A unique identifier for caching the texture.
    /// - Returns: The loaded Metal texture.
    /// - Throws: `TextureError.loadingFailed` if the texture cannot be loaded.
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
    
    /// Loads a texture from data asynchronously.
    ///
    /// If a texture with the same key already exists, it returns the cached texture.
    ///
    /// - Parameters:
    ///   - data: The image data to load.
    ///   - key: A unique identifier for caching the texture.
    /// - Returns: The loaded Metal texture.
    /// - Throws: `TextureError.loadingFailed` if the texture cannot be loaded.
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
    
    /// Creates a blank texture with the specified dimensions.
    ///
    /// - Parameters:
    ///   - width: The width of the texture in pixels.
    ///   - height: The height of the texture in pixels.
    ///   - pixelFormat: The pixel format of the texture.
    ///   - key: A unique identifier for caching the texture.
    /// - Returns: The created Metal texture, or nil if creation fails.
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
    
    /// Retrieves a cached texture by its key.
    ///
    /// - Parameter key: The unique identifier of the texture.
    /// - Returns: The cached texture, or nil if not found.
    public func getTexture(for key: String) -> MTLTexture? {
        return textures[key]
    }
    
    /// Removes a cached texture.
    ///
    /// - Parameter key: The unique identifier of the texture to remove.
    public func removeTexture(for key: String) {
        textures.removeValue(forKey: key)
    }
    
    /// Removes all cached textures.
    public func removeAllTextures() {
        textures.removeAll()
    }
}