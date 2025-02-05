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
    // 深度ステンシル状態
    var depthStencilState: MTLDepthStencilState!

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
        // デバイスの設定
        self.device = MTLCreateSystemDefaultDevice()
        // 背景色を白に設定
        self.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        // カラーバッファのピクセルフォーマット
        self.colorPixelFormat = .bgra8Unorm
        // 深度バッファのピクセルフォーマットを設定
        self.depthStencilPixelFormat = .depth32Float
        
        self.commandQueue = device?.makeCommandQueue()
        
        createDepthStencilState()
        createPipelineStates()
        createVertexBuffers()
    }

    // MARK: - 深度ステンシル状態の作成
    func createDepthStencilState() {
        guard let device = device else { return }
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        // 深度テスト：深度値が小さい（手前）の方を表示
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }

    // MARK: - パイプライン状態の作成（2種類）
    func createPipelineStates() {
        guard let device = device,
              let library = device.makeDefaultLibrary() else {
            fatalError("Metalのセットアップに失敗")
        }
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunctionA = library.makeFunction(name: "fragment_main_A")
        let fragmentFunctionB = library.makeFunction(name: "fragment_main_B")
        
        // 共通の頂点ディスクリプタ
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3  // position (x, y, z)
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // パイプライン A （手前の三角形用）
        let pipelineDescriptorA = MTLRenderPipelineDescriptor()
        pipelineDescriptorA.vertexFunction = vertexFunction
        pipelineDescriptorA.fragmentFunction = fragmentFunctionA
        pipelineDescriptorA.vertexDescriptor = vertexDescriptor
        pipelineDescriptorA.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptorA.depthAttachmentPixelFormat = depthStencilPixelFormat
        
        // パイプライン B （奥の三角形用）
        let pipelineDescriptorB = MTLRenderPipelineDescriptor()
        pipelineDescriptorB.vertexFunction = vertexFunction
        pipelineDescriptorB.fragmentFunction = fragmentFunctionB
        pipelineDescriptorB.vertexDescriptor = vertexDescriptor
        pipelineDescriptorB.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptorB.depthAttachmentPixelFormat = depthStencilPixelFormat

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
        
        // ここでは、両三角形の中心がほぼ一致するように設定しています。
        // 手前の三角形（A：小さい、Z = 0.0）
        // 頂点は次の通り：
        //   v0: (-0.2,  0.2, 0.0)
        //   v1: (-0.3, -0.2, 0.0)
        //   v2: (-0.1, -0.2, 0.0)
        let verticesA: [SIMD3<Float>] = [
            SIMD3<Float>(-0.2,  0.2, 0.0),
            SIMD3<Float>(-0.3, -0.2, 0.0),
            SIMD3<Float>(-0.1, -0.2, 0.0)
        ]
        vertexBufferA = device.makeBuffer(bytes: verticesA,
                                          length: verticesA.count * MemoryLayout<SIMD3<Float>>.size,
                                          options: [])
        
        // 奥の三角形（B：大きい、Z = 0.5）
        // 手前の三角形の重心（約 (-0.2, -0.07)）を中心に、拡大（例：3倍）した頂点座標です。
        //   v0: (-0.2,  0.74, 0.5)
        //   v1: (-0.5, -0.46, 0.5)
        //   v2: ( 0.1, -0.46, 0.5)
        let verticesB: [SIMD3<Float>] = [
            SIMD3<Float>(-0.2,  0.74, 0.5),
            SIMD3<Float>(-0.5, -0.46, 0.5),
            SIMD3<Float>( 0.1, -0.46, 0.5)
        ]
        vertexBufferB = device.makeBuffer(bytes: verticesB,
                                          length: verticesB.count * MemoryLayout<SIMD3<Float>>.size,
                                          options: [])
    }

    // MARK: - 描画処理
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor else { return }
        
        // 深度バッファのクリア値（1.0 = 最も遠い）
        descriptor.depthAttachment.clearDepth = 1.0
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        // 深度ステンシル状態を設定
        encoder.setDepthStencilState(depthStencilState)

        // --- 手前の三角形 (A: 赤、Z = 0.0) の描画 ---
        encoder.setRenderPipelineState(pipelineStateA)
        encoder.setVertexBuffer(vertexBufferA, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        // --- 奥の三角形 (B: 青、Z = 0.5) の描画 ---
        encoder.setRenderPipelineState(pipelineStateB)
        encoder.setVertexBuffer(vertexBufferB, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
