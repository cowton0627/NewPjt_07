//
//  AstroCollectionViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/16.
//

import UIKit

// =============================================================================
// MARK: - Model
// =============================================================================

struct Astro: Codable {
    var title: String?
    var url: URL?
    let hdurl: String?
    var durl: URL? {
        // hdurl 可能含未編碼字元，先做 URL 安全編碼再轉 URL
        guard let hdurl = hdurl,
              let encoded = hdurl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encoded)
    }

    var date: Date?
    var copyright: String?
    var description: String?
}

// =============================================================================
// MARK: - Service - ImageLoader
// =============================================================================
//
// 改善重點：取代原本主線程同步呼叫 `NSData(contentsOf:)` 的做法。
// 1. URLSession 背景下載：避免阻塞主線程，UI 滑動才會順
// 2. NSCache 記憶體快取：回滑動同一張不再重抓
// 3. CGImageSourceCreateThumbnailAtIndex 縮圖（downsample）：
//    NASA 原圖動輒數 MB / 數千 px，直接塞 UIImageView 會吃光記憶體並拖慢滑動。
//    用 ImageIO 在 decode 階段就縮成 cell 需要的尺寸，記憶體大幅下降。
// 4. 回傳 URLSessionDataTask 讓 caller 可在 cell 重用時 cancel 舊請求，
//    避免「先進來的 cell」收到「晚回來的舊圖」造成圖跳。

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024   // 約 100 MB
    }

    /// 載入圖片：先查 cache，沒有就背景下載 + downsample + 存 cache。
    /// - Returns: 真的有發出網路請求時回傳 task（caller 可 cancel）；命中 cache 時回傳 nil。
    @discardableResult
    func load(from url: URL,
              targetSize: CGSize,
              completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {

        // 1) 命中 cache：直接同步回呼，不開背景任務
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        // 2) 背景下載
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                // 被 cancel 也會走這條（NSURLErrorCancelled），不視為錯誤
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }
                print("ImageLoader error: \(error)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data,
                  let image = Self.downsample(data: data, to: targetSize) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // 用 data.count 當 cost，cache 才能精確控制總量
            self?.cache.setObject(image, forKey: url as NSURL, cost: data.count)

            // 3) 回主線程更新 UI
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }

    /// 在 decode 時就把圖縮到目標尺寸，避免載入後再 resize 的記憶體浪費。
    private static func downsample(data: Data, to pointSize: CGSize) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData,
                                                       sourceOptions as CFDictionary) else {
            return nil
        }
        let scale = UIScreen.main.scale
        // 至少給 100pt 的下限，避免 cell 還沒 layout 時 size 為 0 抓不到圖
        let maxDimensionInPoints = max(pointSize.width, pointSize.height, 100)
        let maxDimensionInPixels = maxDimensionInPoints * scale

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source,
                                                                0,
                                                                downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

// =============================================================================
// MARK: - Service - AstroService
// =============================================================================
//
// 把 API 抓資料抽出來，VC 不再直接碰 URLSession / JSONDecoder。
// 好處：(1) VC 變薄 (2) 未來想換來源（mock 用本地檔、改 endpoint）只動這裡
// (3) 統一在主線程回 callback，避免 callsite 自己包 DispatchQueue.main

final class AstroService {
    static let shared = AstroService()
    private init() {}

    private let endpoint = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

    enum ServiceError: LocalizedError {
        case invalidURL
        case emptyData
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:      return "資料來源網址無效"
            case .emptyData:       return "沒有取得回傳資料"
            case .decodingFailed:  return "資料解析失敗"
            }
        }
    }

    /// 抓 APOD 清單；callback 一律在主線程
    func fetchAstros(completion: @escaping (Result<[Astro], Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            DispatchQueue.main.async { completion(.failure(ServiceError.invalidURL)) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(ServiceError.emptyData)) }
                return
            }
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(formatter)
            do {
                let astros = try decoder.decode([Astro].self, from: data)
                DispatchQueue.main.async { completion(.success(astros)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(ServiceError.decodingFailed)) }
            }
        }.resume()
    }
}

// =============================================================================
// MARK: - ViewModel
// =============================================================================
//
// AstroListViewModel：管整頁的 [Astro]、發起 fetch、把錯誤往外丟。
// View 只透過 `numberOfItems` / `cellViewModel(at:)` / `astro(at:)` 取資料，
// 不直接碰 model 陣列，也不知道 Service 存在。
//
// AstroCellViewModel：單一 cell 的顯示資料（title / imageURL）。
// cell 收到的是已經處理好的字串與 URL，cell 本身不做格式化。

final class AstroListViewModel {

    private(set) var astros: [Astro] = []

    /// View 應該在 viewDidLoad 註冊；資料更新時主線程回呼
    var onAstrosUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    var numberOfItems: Int { astros.count }

    func astro(at index: Int) -> Astro { astros[index] }

    func cellViewModel(at index: Int) -> AstroCellViewModel {
        AstroCellViewModel(astro: astros[index])
    }

    func fetch() {
        AstroService.shared.fetchAstros { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.astros = list
                self.onAstrosUpdated?()
            case .failure(let error):
                self.onError?(error.localizedDescription)
            }
        }
    }
}

final class AstroCellViewModel {
    let title: String?
    let imageURL: URL?

    init(astro: Astro) {
        self.title = astro.title
        self.imageURL = astro.url
    }
}

// =============================================================================
// MARK: - View - Cell
// =============================================================================

class AstroCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!

    // 改善重點：cell 重用時持有當前載入任務，再次 dequeue 前先 cancel 舊任務，
    // 否則快速滑動下，舊請求晚回來會把錯的圖貼到新 cell（俗稱 image flicker）。
    private var currentTask: URLSessionDataTask?

    // 載入時用 indicator 提示尚未到圖，避免使用者看到一片空白
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

    // 底部漸層遮罩：讓白色標題壓在圖片上仍清楚可讀
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
        // 縮圖卡片化：圓角 + clipping
        contentView.layer.cornerRadius  = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor     = UIColor(white: 0.08, alpha: 1)

        // 圖片填滿 + 顯示占位深色
        showImg.contentMode        = .scaleAspectFill
        showImg.clipsToBounds      = true
        showImg.backgroundColor    = UIColor(white: 0.12, alpha: 1)

        // 標題：壓在圖片底部，白字、細體、僅一行省略
        titleLabel.font            = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor       = .white
        titleLabel.numberOfLines   = 2
        titleLabel.textAlignment   = .left
        titleLabel.backgroundColor = .clear
        titleLabel.layer.shadowColor   = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.6
        titleLabel.layer.shadowOffset  = CGSize(width: 0, height: 0.5)
        titleLabel.layer.shadowRadius  = 1.5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 漸層遮罩跟著圖片大小走，覆蓋下半部
        let h = showImg.bounds.height
        titleGradient.frame = CGRect(
            x: 0,
            y: h * 0.55,
            width: showImg.bounds.width,
            height: h * 0.45
        )
    }

    /// MVVM：cell 只接 view model，不接 raw model
    func configure(with viewModel: AstroCellViewModel) {
        titleLabel.text = viewModel.title

        // 先取消上一張的下載，避免回呼覆蓋
        currentTask?.cancel()
        currentTask = nil
        showImg.image = nil

        guard let url = viewModel.imageURL else { return }
        indicator.startAnimating()

        currentTask = ImageLoader.shared.load(
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
    }
}

// =============================================================================
// MARK: - View - ViewController
// =============================================================================

class AstroCollectionViewController: UICollectionViewController {

    // MVVM：VC 只持有 ViewModel，不再持有 [Astro] 與直接打 API
    private let viewModel = AstroListViewModel()

    @IBSegueAction func showDetail(_ coder: NSCoder) -> DetailViewController? {
        let controller = DetailViewController(coder: coder)
        if let row = collectionView.indexPathsForSelectedItems?.first?.row {
            // Detail 的 ViewModel 在這裡注入；DetailVC 自己不知道 Astro 哪來
            controller?.viewModel = AstroDetailViewModel(astro: viewModel.astro(at: row))
        }
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 改善重點：補一個 URLCache 容量，讓圖片走 HTTP cache 流程，
        // App 再次冷啟動時若 server 帶 ETag/Last-Modified 可走 304，免再下載
        URLCache.shared = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: nil
        )

        applyAppearance()
        configureFlowLayout()
        bindViewModel()

        viewModel.fetch()
    }

    /// closure binding：VM 通知 View 該重畫 / 該顯示錯誤
    private func bindViewModel() {
        viewModel.onAstrosUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.configureFlowLayout()
        })
    }

    // MARK: - Appearance

    private func applyAppearance() {
        // 深色底襯托星空圖；保留系統 dark/light 適應
        collectionView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.04, alpha: 1)
                : UIColor(white: 0.96, alpha: 1)
        }
        collectionView.alwaysBounceVertical = true

        // 大標題 + 中文 title
        navigationItem.title = "每日天文圖"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    private func configureFlowLayout() {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let columns: CGFloat = 3
        let spacing: CGFloat = 6
        let sideInset: CGFloat = 12
        let totalSpacing = spacing * (columns - 1) + sideInset * 2
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)

        flowLayout.itemSize = CGSize(width: width, height: width)   // 正方形
        flowLayout.estimatedItemSize = .zero
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: sideInset,
                                               left: sideInset,
                                               bottom: sideInset,
                                               right: sideInset)
        flowLayout.invalidateLayout()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                      for: indexPath) as! AstroCollectionCell
        cell.configure(with: viewModel.cellViewModel(at: indexPath.row))
        return cell
    }

    private func showError(_ message: String) {
        // 改善重點：原本 error 直接被忽略，現在至少給使用者一個提示而不是無聲無息空白
        let alert = UIAlertController(title: "載入失敗", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - local-2021 封存版本（註解保留，原檔來自 local-2021 分支 commit 1099172）
/*
//
//  AstroCollectionViewController.swift
//  NewPjt_07
//  Created by 鄭淳澧 on 2021/6/16.
//

import UIKit

struct Astro: Codable {
    var title: String
    var url: URL
    let hdurl: String   //因hdurl在解析時報錯, 故先設為String, 再轉為url
    var durl: URL? {
        hdurl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap { URL(string: $0) }
    }

    var date: Date
    var copyright: String
    var description: String?
}

class AstroCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!

}

class AstroCollectionViewController: UICollectionViewController {
    var astros: [Astro] = []

    //使用Cache部份
//    let imageCache = NSCache<NSURL, UIImage>()

    @IBSegueAction func detailShowed(_ coder: NSCoder) -> DetailCollectionViewController? {
        let controller = DetailCollectionViewController(coder: coder)
        if let row = collectionView.indexPathsForSelectedItems?.first?.row {
            controller?.astro = astros[row]
        }
    return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let diskCapacity = 500 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: URLCache.shared.memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        print(NSHomeDirectory())

        getInfo()   //呼叫解析API的function

//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        let width = ( collectionView.bounds.width - 1 * 3 ) / 4     //塞四張圖的寬度計算
        let height = ( collectionView.bounds.width - 1 * 3 ) / 4    //高度同寬度

        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
            flowLayout?.itemSize = CGSize(width: width, height: height)
            flowLayout?.estimatedItemSize = .zero
            flowLayout?.minimumInteritemSpacing = 1
            flowLayout?.minimumLineSpacing = 1

    }

    //設置cell
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { astros.count }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! AstroCollectionCell

        let astro = astros[indexPath.row]
        cell.titleLabel.text = astro.title  //設定titleLabel

        DispatchQueue.global(qos: .userInteractive).async { [self] in
            if case let image = downsample(imageAt: astro.url, to: CGSize(width: 200, height: 200), scale: 0.8) {
                DispatchQueue.main.async {
                    cell.showImg.image = image
                }
            }
        }
        return cell

        //不使用縮圖方法
//        DispatchQueue.global(qos: .userInteractive).async {
//            let imageData = NSData(contentsOf: astro.url)
//            if let image = UIImage(data: imageData! as Data) {
//                DispatchQueue.main.async {
//                    cell.showImg.image = image
//                }
//            }
//        }

        //使用Cache, 直接在主線程載入時
//        let imageData = NSData(contentsOf: astro.url!)
//        let image = UIImage(data: imageData! as Data)
//        self.imageCache.setObject(image!, forKey: astro.url as! NSURL)
//        cell.showImg.image = image


    }

    func getInfo() {
        let urlStr = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

            if let url = URL(string: urlStr) {
                URLSession.shared.dataTask(with: url) {(data, reponse, error) in
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    decoder.dateDecodingStrategy = .formatted(formatter)

                    if let data = data {
                        do {
                            let astro = try decoder.decode([Astro].self, from: data)
                            self.astros = astro

                            //如果使用Cache
//                            self.imageCache.setObject(image, forKey: url as NSURL)

                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        } catch {
                            print(error)
                        }
                    }
                }.resume()

            }else {
                print("Invalid URL.")
            }
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
