//
//  AstroCollectionCell.swift
//  StellarAPOD
//
//  縮圖牆單格：圓角卡片 + 圖片底部漸層遮罩 + 白色標題。
//  cell 重用時取消上一張下載任務，避免「晚到的圖蓋掉新 cell」。
//

import UIKit

class AstroCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!

    var imageLoader: ImageLoading = ImageLoader.shared
    private var currentTask: ImageLoadCancellable?

    private lazy var indicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        showImg.addSubview(v)
        NSLayoutConstraint.activate([
            v.centerXAnchor.constraint(equalTo: showImg.centerXAnchor),
            v.centerYAnchor.constraint(equalTo: showImg.centerYAnchor)
        ])
        return v
    }()

    /// 底部漸層遮罩，讓白色標題壓在圖片上仍清楚可讀
    private lazy var titleGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0.0)
        g.endPoint   = CGPoint(x: 0.5, y: 1.0)
        showImg.layer.insertSublayer(g, below: titleLabel.layer)
        return g
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.layer.cornerRadius  = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor     = UIColor(white: 0.08, alpha: 1)

        showImg.contentMode     = .scaleAspectFill
        showImg.clipsToBounds   = true
        showImg.backgroundColor = UIColor(white: 0.12, alpha: 1)

        titleLabel.font            = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor       = .white
        titleLabel.numberOfLines   = 2
        titleLabel.textAlignment   = .left
        titleLabel.backgroundColor = .clear
        titleLabel.layer.shadowColor   = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.6
        titleLabel.layer.shadowOffset  = CGSize(width: 0, height: 0.5)
        titleLabel.layer.shadowRadius  = 1.5
        isAccessibilityElement = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = showImg.bounds.height
        titleGradient.frame = CGRect(
            x: 0,
            y: h * 0.55,
            width: showImg.bounds.width,
            height: h * 0.45
        )
    }

    /// MVVM：cell 只接 view model
    func configure(with viewModel: AstroCellViewModel) {
        titleLabel.text = viewModel.title

        currentTask?.cancel()
        currentTask = nil
        showImg.image = nil

        guard let url = viewModel.imageURL else { return }
        indicator.startAnimating()

        accessibilityLabel = viewModel.title ?? "天文圖片"
        accessibilityHint = "點兩下查看詳情"

        currentTask = imageLoader.load(
            from: url,
            targetSize: showImg.bounds.size
        ) { [weak self] image in
            self?.indicator.stopAnimating()
            self?.showImg.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask?.cancel()
        currentTask = nil
        showImg.image = nil
        indicator.stopAnimating()
        titleLabel.text = nil
        accessibilityLabel = nil
    }
}
