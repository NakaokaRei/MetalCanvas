import Foundation
import Metal
import simd

public enum UniformType {
    case float
    case float2
    case float3
    case float4
    case int
    case int2
    case int3
    case int4
    case matrix2x2
    case matrix3x3
    case matrix4x4
    case texture2D
}

public struct Uniform {
    public let name: String
    public let type: UniformType
    public var value: Any
    
    public init(name: String, type: UniformType, value: Any) {
        self.name = name
        self.type = type
        self.value = value
    }
}

public class Uniforms {
    private var uniforms: [String: Uniform] = [:]
    public var isDirty: Bool = false
    
    public init() {
        setupDefaultUniforms()
    }
    
    private func setupDefaultUniforms() {
        set("u_resolution", value: SIMD2<Float>(0, 0), type: .float2)
        set("u_time", value: Float(0), type: .float)
        set("u_mouse", value: SIMD2<Float>(0, 0), type: .float2)
        set("u_date", value: SIMD4<Float>(0, 0, 0, 0), type: .float4)
    }
    
    public func set(_ name: String, value: Any, type: UniformType) {
        uniforms[name] = Uniform(name: name, type: type, value: value)
        isDirty = true
    }
    
    public func get(_ name: String) -> Uniform? {
        return uniforms[name]
    }
    
    public func update(_ name: String, value: Any) {
        if var uniform = uniforms[name] {
            uniform.value = value
            uniforms[name] = uniform
            isDirty = true
        }
    }
    
    public func clean() {
        isDirty = false
    }
    
    public func createBuffer(device: MTLDevice) -> MTLBuffer? {
        let bufferSize = calculateBufferSize()
        guard bufferSize > 0 else { return nil }
        
        return device.makeBuffer(length: bufferSize, options: .storageModeShared)
    }
    
    public func updateBuffer(_ buffer: MTLBuffer) {
        var offset = 0
        let contents = buffer.contents()
        
        for (_, uniform) in uniforms.sorted(by: { $0.key < $1.key }) {
            writeUniform(uniform, to: contents, at: &offset)
        }
    }
    
    private func calculateBufferSize() -> Int {
        var size = 0
        
        for (_, uniform) in uniforms {
            switch uniform.type {
            case .float, .int:
                size += 4
            case .float2, .int2:
                size += 8
            case .float3, .int3:
                size += 12
            case .float4, .int4:
                size += 16
            case .matrix2x2:
                size += 16
            case .matrix3x3:
                size += 36
            case .matrix4x4:
                size += 64
            case .texture2D:
                break
            }
            
            size = (size + 15) & ~15
        }
        
        return size
    }
    
    private func writeUniform(_ uniform: Uniform, to buffer: UnsafeMutableRawPointer, at offset: inout Int) {
        switch uniform.type {
        case .float:
            if let value = uniform.value as? Float {
                buffer.storeBytes(of: value, toByteOffset: offset, as: Float.self)
                offset += 4
            }
        case .float2:
            if let value = uniform.value as? SIMD2<Float> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD2<Float>.self)
                offset += 8
            }
        case .float3:
            if let value = uniform.value as? SIMD3<Float> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD3<Float>.self)
                offset += 12
            }
        case .float4:
            if let value = uniform.value as? SIMD4<Float> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD4<Float>.self)
                offset += 16
            }
        case .int:
            if let value = uniform.value as? Int32 {
                buffer.storeBytes(of: value, toByteOffset: offset, as: Int32.self)
                offset += 4
            }
        case .int2:
            if let value = uniform.value as? SIMD2<Int32> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD2<Int32>.self)
                offset += 8
            }
        case .int3:
            if let value = uniform.value as? SIMD3<Int32> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD3<Int32>.self)
                offset += 12
            }
        case .int4:
            if let value = uniform.value as? SIMD4<Int32> {
                buffer.storeBytes(of: value, toByteOffset: offset, as: SIMD4<Int32>.self)
                offset += 16
            }
        case .matrix2x2:
            if let value = uniform.value as? simd_float2x2 {
                buffer.storeBytes(of: value, toByteOffset: offset, as: simd_float2x2.self)
                offset += 16
            }
        case .matrix3x3:
            if let value = uniform.value as? simd_float3x3 {
                buffer.storeBytes(of: value, toByteOffset: offset, as: simd_float3x3.self)
                offset += 36
            }
        case .matrix4x4:
            if let value = uniform.value as? simd_float4x4 {
                buffer.storeBytes(of: value, toByteOffset: offset, as: simd_float4x4.self)
                offset += 64
            }
        case .texture2D:
            break
        }
        
        offset = (offset + 15) & ~15
    }
}