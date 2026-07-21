//
//  DetailViewCell.swift
//  StellarAPOD
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

    var imageLoader: ImageLoading = ImageLoader.shared
    private var currentTask: ImageLoadCancellable?

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

    /// imageView 與 desLabel 的左右邊距（pt）。
    /// 變動時 DetailViewController.heightForRowAt 內的 descWidth 也要跟著調。
    static let horizontalInset: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTypography()
        relaxStoryboardConstraints()
        adjustHorizontalInsets()
    }

    /// storyboard 中 showImg 左右是 0pt、desLabel 左右是 7.5pt，貼太緊。
    /// 在這裡覆寫 constant 改成 horizontalInset。
    private func adjustHorizontalInsets() {
        let inset = Self.horizontalInset
        for c in contentView.constraints {
            let firstView = c.firstItem as? UIView
            let secondView = c.secondItem as? UIView
            // showImg.leading = contentView.leading + inset
            if c.firstAttribute == .leading && firstView === showImg {
                c.constant = inset
            }
            // contentView.trailing = showImg.trailing + inset
            if c.firstAttribute == .trailing && secondView === showImg {
                c.constant = inset
            }
            // desLabel.leading = contentView.leading + inset
            if c.firstAttribute == .leading && firstView === desLabel {
                c.constant = inset
            }
            // contentView.trailing = desLabel.trailing + inset
            if c.firstAttribute == .trailing && secondView === desLabel {
                c.constant = inset
            }
        }

        // storyboard 沒給 titleLabel 任何 leading/trailing 約束，
        // 配合 numberOfLines = 0 補上「不能超出邊界」的限制，過長就自動換行。
        // 用 GTE/LTE 而非 equal，配合 centerX 約束：短 title 仍然按 intrinsic 寬居中，
        // 長 title 撞到邊界才 wrap。
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: inset),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -inset),
        ])
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
        titleLabel.lineBreakMode = .byWordWrapping

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

        currentTask = imageLoader.load(
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
