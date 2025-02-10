//
//  ViewController.swift
//  TextureLoadSample
//
//  Created by rei.nakaoka on 2025/02/10.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let metalView = MetalView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        view.addSubview(metalView)
    }
}


