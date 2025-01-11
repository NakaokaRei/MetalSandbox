//
//  ViewController.swift
//  RotateTriangle
//
//  Created by NakaokaRei on 2025/01/11.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let metalView = MetalView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        view.addSubview(metalView)
    }
}


// Extension
import simd

extension matrix_float4x4 {
    init(rotationAngle angle: Float, axis: SIMD3<Float>) {
        let normalizedAxis = normalize(axis)
        let ct = cos(angle)
        let st = sin(angle)
        let ci = 1 - ct
        let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z

        self.init(columns: (
            SIMD4<Float>(ct + ci * x * x, ci * x * y - z * st, ci * x * z + y * st, 0),
            SIMD4<Float>(ci * y * x + z * st, ct + ci * y * y, ci * y * z - x * st, 0),
            SIMD4<Float>(ci * z * x - y * st, ci * z * y + x * st, ct + ci * z * z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }
}

