import MetalKit
import simd

// 頂点構造体（位置：float4、テクスチャ座標（uv）：float2）
struct Vertex {
    var position: SIMD4<Float>
    var uv: SIMD2<Float>
}

class MetalView: MTKView {

    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!

    // テクスチャとサンプラー
    var texture: MTLTexture!
    var samplerState: MTLSamplerState!

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
        // デバイス設定
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.colorPixelFormat = .bgra8Unorm
        // 背景色（任意：ここでは白）
        self.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)

        // パイプライン状態、頂点バッファ、テクスチャ、サンプラーを作成
        createPipelineState()
        createVertexBuffer()
        loadTexture()
        createSamplerState()
    }

    // パイプライン状態の作成
    func createPipelineState() {
        guard let device = self.device else { return }
        let library = device.makeDefaultLibrary()!

        // シェーダー関数の取得
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        // 頂点ディスクリプタの作成（位置と uv）
        let vertexDescriptor = MTLVertexDescriptor()
        // 位置 (float4) ：属性0
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // uv (float2) ：属性1
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        // レイアウト設定
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // パイプライン記述子の作成
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("パイプライン状態の作成に失敗: \(error)")
        }
    }

    // 頂点バッファの作成
    func createVertexBuffer() {
        // 三角形の頂点データ（NDC 座標と uv 座標）
        let vertices: [Vertex] = [
            Vertex(position: SIMD4<Float>(-0.5, -0.5, 0, 1),
                   uv: SIMD2<Float>(0, 0)),
            Vertex(position: SIMD4<Float>( 0.5, -0.5, 0, 1),
                   uv: SIMD2<Float>(1, 0)),
            Vertex(position: SIMD4<Float>( 0.0,  0.5, 0, 1),
                   uv: SIMD2<Float>(0.5, 1))
        ]

        vertexBuffer = device?.makeBuffer(bytes: vertices,
                                          length: MemoryLayout<Vertex>.stride * vertices.count,
                                          options: [])
    }

    // テクスチャの読み込み
    func loadTexture() {
        guard let device = self.device else { return }
        let textureLoader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: "texture", withExtension: "png") else {
            fatalError("texture.png が見つかりません")
        }
        do {
            texture = try textureLoader.newTexture(URL: url,
                                                   options: [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft])
        } catch {
            fatalError("テクスチャ読み込みエラー: \(error)")
        }
    }

    // サンプラー状態の作成
    func createSamplerState() {
        guard let device = self.device else { return }
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    // MARK: - 描画処理
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // フラグメントシェーダーへテクスチャとサンプラーを設定
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
