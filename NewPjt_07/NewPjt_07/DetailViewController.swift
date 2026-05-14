//
//  DetailViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

// =============================================================================
// MARK: - ViewModel
// =============================================================================
//
// AstroDetailViewModel：把「Astro → 詳情頁畫面該顯示什麼」這段邏輯封裝起來。
// 包含：
//   - 純文字屬性（title / copyrightText）
//   - 已格式化的 attributedString（描述加行距、日期加字距）
//   - 給 tableView heightForRow 計算用的描述高度
// View 端只負責呈現 VM 回傳的字串/屬性字串，不做格式化、不知道 DateFormatter。

final class AstroDetailViewModel {

    private let astro: Astro

    init(astro: Astro) {
        self.astro = astro
    }

    // MARK: 純資料屬性

    var title: String? { astro.title }
    var imageURL: URL? { astro.durl }

    var copyrightText: String? {
        guard let cpy = astro.copyright,
              !cpy.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return "© \(cpy)"
    }

    // MARK: 給 View 直接套用的 attributedString

    /// 日期：紅色、字距加大、全大寫 caption
    func dateAttributedText() -> NSAttributedString {
        let text: String
        if let date = astro.date {
            text = Self.dateFormatter.string(from: date).uppercased()
        } else {
            text = "—"
        }
        return NSAttributedString(
            string: text,
            attributes: [
                .kern: 1.5,
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.systemRed
            ]
        )
    }

    /// 描述：行距 5、justified；nil/空字串回 nil
    func descriptionAttributedText() -> NSAttributedString? {
        guard let text = astro.description, !text.isEmpty else { return nil }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 5
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .justified
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraph,
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )
    }

    /// 描述在指定寬度下需要的高度（heightForRow 算 cell 高用）。
    /// 跟 descriptionAttributedText() 用同一組 attribute，計算結果才會跟實際渲染一致。
    func descriptionHeight(forWidth width: CGFloat) -> CGFloat {
        guard let attr = descriptionAttributedText(), width > 0 else { return 0 }
        let rect = attr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(rect.height)
    }

    // MARK: DateFormatter（建構成本高，整 app 共用一份）

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM. dd"
        return f
    }()
}

// =============================================================================
// MARK: - View - Cell
// =============================================================================

class DetailViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!

    // 改善重點：跟 collection cell 一樣，重用時要 cancel 上一張 HD 圖的下載任務，
    // 避免從 A 篇 detail 退出去看 B 篇時，A 的圖才下載完蓋掉 B 的畫面。
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

    /// storyboard 中 dateLabel / cpyLabel 對 contentView 設了 centerY 約束，
    /// 一旦 cell 高度增加（容納長描述），這兩條會把元件位置往下拉、整個版面糊掉。
    /// 拆掉它們，只保留 top→bottom 的連鎖約束，讓 cell 能單純由上往下展開。
    private func relaxStoryboardConstraints() {
        let targets: [UIView?] = [dateLabel, cpyLabel]
        for c in contentView.constraints
        where c.firstAttribute == .centerY && c.secondAttribute == .centerY {
            if let v = c.firstItem as? UIView, targets.contains(where: { $0 === v }) {
                c.isActive = false
            }
        }
    }

    /// 只放「跟資料無關的視覺基底設定」；
    /// 跟資料有關的文字/顏色（日期顏色、描述行距）由 VM 給的 attributedString 蓋上去。
    private func applyTypography() {
        selectionStyle = .none

        // 圖片：星空照用黑底襯托、不裁切
        showImg.contentMode = .scaleAspectFit
        showImg.backgroundColor = .black
        showImg.clipsToBounds = true
        showImg.layer.cornerRadius = 8

        // 標題：粗體大字、可多行
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        // 版權：灰、小字
        cpyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        cpyLabel.textColor = .secondaryLabel
        cpyLabel.numberOfLines = 2
        cpyLabel.textAlignment = .center

        // 日期 / 描述：對齊與多行設定即可，色彩與字距由 VM attributedString 帶
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
            // 改善重點：用 cross dissolve 讓圖出現比較平順，不是「啪」一下硬切
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

// =============================================================================
// MARK: - View - ViewController
// =============================================================================

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// MVVM：由上一頁透過 IBSegueAction 注入；VC 不知道 Astro 哪來
    var viewModel: AstroDetailViewModel!

    @IBOutlet weak var detailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self

        // 改善重點：storyboard 中 desLabel 沒有 bottom→contentView 的 constraint，
        // 不能改 automaticDimension（會塌掉），改在 heightForRow 手動算高。
        detailTableView.separatorStyle = .none
        detailTableView.showsVerticalScrollIndicator = false
        detailTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        navigationItem.largeTitleDisplayMode = .never
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    /// 依描述文字量動態算 cell 高度，讓 tableView 能捲動長描述
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // storyboard 上半部固定區塊（date + image + title + cpy + 各 spacing）約 342pt
        let headerHeight: CGFloat = 342
        let bottomPadding: CGFloat = 24
        // desLabel 左右 leading/trailing 各 7.5pt（storyboard 設定）
        let descWidth = tableView.bounds.width - 15
        return headerHeight + viewModel.descriptionHeight(forWidth: descWidth) + bottomPadding
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailViewCell",
                                                 for: indexPath) as! DetailViewCell
        cell.configure(with: viewModel)
        return cell
    }
}

// MARK: - local-2021 封存版本（註解保留，原檔來自 local-2021 分支 commit 1099172）
/*
//
//  DetailViewController.swift
//  NewPjt_07
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

class DetailViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var astro: Astro!

    @IBOutlet weak var detailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self
    }

    //設置cell
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailViewCell", for: indexPath) as! DetailViewCell
        cell.titleLabel.text = astro.title
        cell.cpyLabel.text = astro.copyright
        cell.desLabel.text = astro.description


        let url = Bundle.main.url(forResource: astro.hdurl,
                                              withExtension: "tiff")!

        //使用縮圖方法2
        DispatchQueue.global(qos: .userInitiated).async { [self] in
          let image = resizedImage(at: url, for: cell.showImg.bounds.size)

          DispatchQueue.main.sync {
            UIView.transition(with: cell.showImg,
                             duration: 1.0,
                             options: [.curveEaseOut, .transitionCrossDissolve],
                             animations: { cell.showImg.image = image })
          }
        }

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM. dd"   //時間轉換成指定格式
        decoder.dateDecodingStrategy = .formatted(formatter)
        let dateStr = formatter.string(from: astro.date)
        cell.dateLabel.text = dateStr          //設定dateLabel

        return cell


        //在主線程載入圖片, 卡主線程的情況
//                let imageData = NSData(contentsOf: astro.durl!)
//                let image = UIImage(data: imageData! as Data)
//                cell.showImg.image = image

        //在背景載入圖片, 不卡主線程的情況
//                DispatchQueue.global(qos: .userInteractive).async { [self] in
//                    let imageData = NSData(contentsOf: astro.durl!)
//                    if let image = UIImage(data: imageData! as Data) {
//                        DispatchQueue.main.async {
//                            cell.showImg.image = image
//                        }
//                    }
//                }

        //使用縮圖方法1
//                DispatchQueue.global(qos: .userInteractive).async { [self] in
//                    if case let image = downsample(imageAt: astro.durl!, to: CGSize(width: 80, height: 80), scale: 1.0)
//                        DispatchQueue.main.async {
//                                cell.showImg.image = image
//                        }
//                    }
//                }


    }


    //縮圖方法1
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {
       let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
       let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!

       let maxDimentionInPixels = max(pointSize.width, pointSize.height) * scale

       let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceShouldCacheImmediately: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true,
                                 kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels] as CFDictionary
      let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions)!

       return UIImage(cgImage: downsampledImage)
    }


    //縮圖方法2
    func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

}
*/
