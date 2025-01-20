import UIKit
import MetalKit

class ViewController: UIViewController {

    var metalView: MetalView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // MetalViewのインスタンスを作成
        metalView = MetalView(frame: self.view.bounds)
        metalView.translatesAutoresizingMaskIntoConstraints = false

        // ViewControllerのビューに追加
        self.view.addSubview(metalView)

        // Auto Layout制約を使用してMetalViewを画面全体にフィットさせる
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: self.view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // MetalViewのサイズを更新
        metalView.frame = self.view.bounds
    }
}
