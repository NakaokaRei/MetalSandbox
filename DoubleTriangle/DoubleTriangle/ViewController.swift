//
//  ViewController.swift
//  DoubleTriangle
//
//  Created by rei.nakaoka on 2025/02/05.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let metalView = MetalView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        view.addSubview(metalView)
    }
}

