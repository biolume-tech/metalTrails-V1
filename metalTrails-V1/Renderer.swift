import Foundation
import MetalKit
import simd

struct TrailPoint {
    var position: SIMD4<Float> // Match the float4 type
    var color: SIMD4<Float> // Match the float4 type
}

class Renderer: NSObject, MTKViewDelegate {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    
    var trailBuffer: MTLBuffer?
    var frameCountBuffer: MTLBuffer?
    let trailLength = 15  // Number of points in the trail
    var frameCount: UInt32 = 0
    
    init(metalView: MTKView) {
        super.init()
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        setupPipelineState(metalView: metalView)
        setupTrailBuffer()
        setupFrameCountBuffer()
        setupComputePipelineState()
        metalView.delegate = self
    }
    
    private func setupFrameCountBuffer() {
        frameCountBuffer = Renderer.device.makeBuffer(length: MemoryLayout<UInt32>.size, options: [])
    }
    
    private func setupComputePipelineState() {
        guard let computeFunction = Renderer.device.makeDefaultLibrary()?.makeFunction(name: "compute_main") else {
            fatalError("Failed to create compute function")
        }
        
        do {
            computePipelineState = try Renderer.device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
    }
    
    func performComputePass() {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let trailBuffer = trailBuffer,
              let frameCountBuffer = frameCountBuffer else {
            return
        }
        
        frameCount += 1
        memcpy(frameCountBuffer.contents(), &frameCount, MemoryLayout<UInt32>.size)
        
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(trailBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(frameCountBuffer, offset: 0, index: 1)
        
        let gridSize = MTLSize(width: trailLength, height: 1, depth: 1)
        var threadGroupSize = computePipelineState.maxTotalThreadsPerThreadgroup
        if threadGroupSize > trailLength {
            threadGroupSize = trailLength
        }
        let threadgroupSize = MTLSize(width: threadGroupSize, height: 1, depth: 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
    private func setupPipelineState(metalView: MTKView) {
        let vertexFunction = Renderer.device.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.device.makeDefaultLibrary()?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Error creating pipeline state: \(error)")
        }
    }
    
    private func setupTrailBuffer() {
        let initialTrailPoints = [TrailPoint](repeating: TrailPoint(position: SIMD4<Float>(0, 0, 0, 1), color: SIMD4<Float>(1, 0, 0, 1)), count: trailLength)
        trailBuffer = Renderer.device.makeBuffer(bytes: initialTrailPoints, length: MemoryLayout<TrailPoint>.stride * trailLength, options: [])
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size change if necessary.
    }
    
    func draw(in view: MTKView) {
        
        
        
        
        performComputePass() // Perform compute pass before rendering
        
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let trailBuffer = trailBuffer else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set the trailBuffer for both vertex and fragment shaders
        renderEncoder.setVertexBuffer(trailBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(trailBuffer, offset: 0, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: trailLength)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
