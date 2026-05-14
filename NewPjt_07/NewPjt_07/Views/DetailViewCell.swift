//
//  DetailViewCell.swift
//  NewPjt_07
//
//  詳情頁 cell：標題 / 圖 / 日期 / 版權 / 描述。
//  storyboard 內 dateLabel / cpyLabel 對 contentView 有 centerY 約束，
//  cell 變高時會把 layout 拉歪，awakeFromNib 時拆掉。
//

import UIKit

class DetailViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!

    private var currentTask: URLSessionDataTask?

    private lazy var indicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
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

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTypography()
        relaxStoryboardConstraints()
    }

    /// 拆掉 storyboard 中 dateLabel / cpyLabel 對 contentView 的 centerY 約束。
    /// 不拆掉的話 cell 變高（容納長描述）時這兩條會把元件位置拉走，整個版面糊掉。
    private func relaxStoryboardConstraints() {
        let targets: [UIView?] = [dateLabel, cpyLabel]
        for c in contentView.constraints
        where c.firstAttribute == .centerY && c.secondAttribute == .centerY {
            if let v = c.firstItem as? UIView, targets.contains(where: { $0 === v }) {
                c.isActive = false
            }
        }
    }

    /// 跟資料無關的視覺基底；資料相關的字色/字距由 VM 提供的 attributedString 蓋上
    private func applyTypography() {
        selectionStyle = .none

        showImg.contentMode = .scaleAspectFit
        showImg.backgroundColor = .black
        showImg.clipsToBounds = true
        showImg.layer.cornerRadius = 8

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        cpyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        cpyLabel.textColor = .secondaryLabel
        cpyLabel.numberOfLines = 2
        cpyLabel.textAlignment = .center

        dateLabel.textAlignment = .center
        desLabel.numberOfLines = 0
        desLabel.textAlignment = .justified
    }

    /// MVVM：cell 只接 view model
    func configure(with viewModel: AstroDetailViewModel) {
        titleLabel.text = viewModel.title
        cpyLabel.text = viewModel.copyrightText
        dateLabel.attributedText = viewModel.dateAttributedText()
        desLabel.attributedText = viewModel.descriptionAttributedText()
        loadImage(from: viewModel.imageURL)
    }

    private func loadImage(from url: URL?) {
        currentTask?.cancel()
        currentTask = nil
        showImg.image = nil

        guard let url = url else { return }
        indicator.startAnimating()

        currentTask = ImageLoader.shared.load(
            from: url,
            targetSize: showImg.bounds.size
        ) { [weak self] image in
            guard let self = self else { return }
            self.indicator.stopAnimating()
            UIView.transition(with: self.showImg,
                              duration: 0.25,
                              options: [.curveEaseOut, .transitionCrossDissolve],
                              animations: { self.showImg.image = image })
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask?.cancel()
        currentTask = nil
        showImg.image = nil
        indicator.stopAnimating()
    }
}
