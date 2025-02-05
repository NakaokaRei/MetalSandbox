//
//  MetalView.swift
//  DoubleTriangle
//
//  Created by rei.nakaoka on 2025/02/05.
//

import UIKit
import MetalKit
import simd

class MetalView: MTKView {

    var commandQueue: MTLCommandQueue!
    // 各三角形用のパイプライン状態
    var pipelineStateA: MTLRenderPipelineState!
    var pipelineStateB: MTLRenderPipelineState!
    // 各三角形用の頂点バッファ
    var vertexBufferA: MTLBuffer!
    var vertexBufferB: MTLBuffer!

    // MARK: - 初期化
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        commonInit()
    }

    private func commonInit() {
        self.device = MTLCreateSystemDefaultDevice()
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.commandQueue = device?.makeCommandQueue()

        createPipelineStates()
        createVertexBuffers()
    }

    // MARK: - パイプライン状態の作成（2種類）
    func createPipelineStates() {
        guard let device = device,
              let library = device.makeDefaultLibrary() else {
            fatalError("Metalのセットアップに失敗")
        }
        let vertexFunction = library.makeFunction(name: "vertex_main")
        // それぞれ異なるフラグメントシェーダーを使用
        let fragmentFunctionA = library.makeFunction(name: "fragment_main_A")
        let fragmentFunctionB = library.makeFunction(name: "fragment_main_B")

        // 共通の頂点ディスクリプタ
        let vertexDescriptor = MTLVertexDescriptor()
        // attribute(0): position（float3）
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // パイプラインAの設定（三角形A用）
        let pipelineDescriptorA = MTLRenderPipelineDescriptor()
        pipelineDescriptorA.vertexFunction = vertexFunction
        pipelineDescriptorA.fragmentFunction = fragmentFunctionA
        pipelineDescriptorA.vertexDescriptor = vertexDescriptor
        pipelineDescriptorA.colorAttachments[0].pixelFormat = colorPixelFormat

        // パイプラインBの設定（三角形B用）
        let pipelineDescriptorB = MTLRenderPipelineDescriptor()
        pipelineDescriptorB.vertexFunction = vertexFunction
        pipelineDescriptorB.fragmentFunction = fragmentFunctionB
        pipelineDescriptorB.vertexDescriptor = vertexDescriptor
        pipelineDescriptorB.colorAttachments[0].pixelFormat = colorPixelFormat

        do {
            pipelineStateA = try device.makeRenderPipelineState(descriptor: pipelineDescriptorA)
            pipelineStateB = try device.makeRenderPipelineState(descriptor: pipelineDescriptorB)
        } catch {
            fatalError("パイプライン状態の作成に失敗: \(error)")
        }
    }

    // MARK: - 頂点バッファの作成（2つの三角形）
    func createVertexBuffers() {
        guard let device = device else { return }

        // 三角形A：画面左側に配置（例）
        let verticesA: [SIMD3<Float>] = [
            SIMD3<Float>(-0.75,  0.5, 0.0),  // 上
            SIMD3<Float>(-1.25, -0.5, 0.0),  // 左下
            SIMD3<Float>(-0.25, -0.5, 0.0)   // 右下
        ]
        vertexBufferA = device.makeBuffer(bytes: verticesA,
                                          length: verticesA.count * MemoryLayout<SIMD3<Float>>.size,
                                          options: [])

        // 三角形B：画面右側に配置（例）
        let verticesB: [SIMD3<Float>] = [
            SIMD3<Float>(0.75,  0.5, 0.0),   // 上
            SIMD3<Float>(0.25, -0.5, 0.0),   // 左下
            SIMD3<Float>(1.25, -0.5, 0.0)    // 右下
        ]
        vertexBufferB = device.makeBuffer(bytes: verticesB,
                                          length: verticesB.count * MemoryLayout<SIMD3<Float>>.size,
                                          options: [])
    }

    // MARK: - 描画処理
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor else { return }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // --- 三角形A の描画 ---
        encoder.setRenderPipelineState(pipelineStateA)
        encoder.setVertexBuffer(vertexBufferA, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        // --- 三角形B の描画 ---
        encoder.setRenderPipelineState(pipelineStateB)
        encoder.setVertexBuffer(vertexBufferB, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
