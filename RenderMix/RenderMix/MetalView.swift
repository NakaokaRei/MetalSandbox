import UIKit
import MetalKit
import simd

class MetalView: MTKView {

    // Metal関連
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!

    // バッファ
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!

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
        guard let device = self.device else {
            fatalError("Metal not supported on this device.")
        }
        colorPixelFormat = .bgra8Unorm
        commandQueue = device.makeCommandQueue()

        createPipelineState()
        createBuffers()

        // MTKView設定
        enableSetNeedsDisplay = false
        isPaused = false
    }

    // MARK: - パイプライン作成
    private func createPipelineState() {
        guard let device = device else { return }

        let library = device.makeDefaultLibrary()
        let vertexFunction   = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        // 頂点ディスクリプタの設定
        let vertexDescriptor = MTLVertexDescriptor()
        // attribute(0): position (.float3)
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // レイアウト
        // → Swiftでの SIMD3<Float> は実際 16バイト (アライメント含む)
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // RenderPipelineDescriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        // デバッグ出力
        print("MemoryLayout<SIMD3<Float>>.size =", MemoryLayout<SIMD3<Float>>.size) // 16
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    // MARK: - バッファ作成
    private func createBuffers() {
        guard let device = device else { return }

        // 画面全体を覆う 4頂点 (左上, 左下, 右上, 右下)
        // positionのみ (x,y,z)
        let positions: [SIMD3<Float>] = [
            SIMD3<Float>(-1,  1, 0),  // 0: 左上
            SIMD3<Float>(-1, -1, 0),  // 1: 左下
            SIMD3<Float>( 1,  1, 0),  // 2: 右上
            SIMD3<Float>( 1, -1, 0)   // 3: 右下
        ]

        vertexBuffer = device.makeBuffer(
            bytes: positions,
            length: positions.count * MemoryLayout<SIMD3<Float>>.size,
            options: []
        )

        // 2枚の三角形で一枚の四角形を描く
        //  (0,1,2), (2,1,3)
        let indices: [UInt16] = [0, 1, 2,  2, 1, 3]
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.size,
            options: []
        )
    }

    // MARK: - 描画処理
    override func draw(_ rect: CGRect) {
        guard let drawable   = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)

        // 頂点バッファ
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // インデックスバッファを使用
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
