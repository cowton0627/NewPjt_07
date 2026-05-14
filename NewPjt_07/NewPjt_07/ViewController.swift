//
//  ViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        styleEntryButton()
    }

    /// 把首頁那顆 system style 的 "Request" 按鈕，
    /// 改成現代膠囊填色按鈕 + SF Symbol + 中文文案。
    /// 不動 storyboard，從程式碼端找到 button 直接套樣式。
    private func styleEntryButton() {
        guard let button = view.subviews.compactMap({ $0 as? UIButton }).first else {
            return
        }

        // storyboard 同時設了 centerY 與 top→label.bottom，兩條垂直約束打架，
        // 拆掉 centerY 那條，讓按鈕老實貼在標題下方
        for c in view.constraints
        where c.firstAttribute == .centerY && c.secondAttribute == .centerY {
            if (c.firstItem as? UIButton) === button {
                c.isActive = false
            }
        }

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.image = UIImage(systemName: "sparkles")
            config.imagePadding = 8
            config.imagePlacement = .leading
            config.baseBackgroundColor = .systemBlue
            config.baseForegroundColor = .white
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 12, leading: 24, bottom: 12, trailing: 24
            )
            var title = AttributedString("探索圖庫")
            title.font = .systemFont(ofSize: 17, weight: .semibold)
            config.attributedTitle = title
            button.configuration = config
        } else {
            // iOS 14 fallback：手刻同等樣式
            button.setTitle("探索圖庫", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            button.backgroundColor = .systemBlue
            button.tintColor = .white
            button.layer.cornerRadius = 22
            button.contentEdgeInsets = UIEdgeInsets(
                top: 12, left: 24, bottom: 12, right: 24
            )
            if let icon = UIImage(systemName: "sparkles") {
                button.setImage(icon, for: .normal)
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            }
        }

        // 按起來輕微回饋，現代 iOS 按鈕慣例
        button.addAction(UIAction { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }, for: .touchUpInside)
    }
}

