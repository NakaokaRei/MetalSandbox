import UIKit
import MetalKit
import simd

class MetalView: MTKView {

    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!

    var rotationAngle: Float = 0.0
    var lastTouchLocation: CGPoint = .zero

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
        self.commandQueue = device?.makeCommandQueue()

        createPipelineState()
        createVertexBuffer()
    }

    // MARK: - パイプラインの作成
    func createPipelineState() {
        let library = device!.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        // 頂点ディスクリプタの追加
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3   // position (x, y, z)
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    // MARK: - 頂点バッファの作成（単純な三角形）
    func createVertexBuffer() {
        let vertices: [SIMD3<Float>] = [
             SIMD3<Float>(0.0,  0.5, 0.0),  // 上
             SIMD3<Float>(-0.5, -0.5, 0.0), // 左下
             SIMD3<Float>(0.5, -0.5, 0.0)   // 右下
        ]

        vertexBuffer = device?.makeBuffer(bytes: vertices,
                                          length: vertices.count * MemoryLayout<SIMD3<Float>>.size,
                                          options: [])
    }

    // MARK: - 描画処理
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // 回転行列の適用
        var rotationMatrix = matrix_float4x4(rotationAngle: rotationAngle, axis: SIMD3<Float>(0, 1, 0))
        encoder?.setVertexBytes(&rotationMatrix, length: MemoryLayout<matrix_float4x4>.size, index: 1)

        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

    // MARK: - タッチ操作で回転
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            lastTouchLocation = touch.location(in: self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let deltaX = Float(location.x - lastTouchLocation.x) / 100.0
        rotationAngle += deltaX  // 回転角度を更新
        lastTouchLocation = location
    }
}
