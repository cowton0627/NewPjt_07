//
//  ViewController.swift
//  NewPjt_07
//
//  首頁：標題 + 進入圖庫的 CTA 按鈕。
//  storyboard 中已連好按鈕的 segue 到 AstroCollectionViewController。
//  這裡只負責把 system style 按鈕重新樣式化。
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        styleEntryButton()
    }

    /// 把 storyboard 上原本的 "Request" system 按鈕，改成填色膠囊 + SF Symbol + 中文文案
    private func styleEntryButton() {
        guard let button = view.subviews.compactMap({ $0 as? UIButton }).first else {
            return
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
            // iOS 14 fallback
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

        button.addAction(UIAction { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }, for: .touchUpInside)
    }
}
