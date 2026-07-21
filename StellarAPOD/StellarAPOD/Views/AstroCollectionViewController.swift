//
//  AstroCollectionViewController.swift
//  StellarAPOD
//
//  縮圖牆。VC 只持有 ViewModel，不再持有 [Astro] 或直接打 API。
//

import UIKit

class AstroCollectionViewController: UICollectionViewController {

    private let viewModel = AstroListViewModel()

    private lazy var stateView: CollectionStateView = {
        let view = CollectionStateView()
        view.onRetry = { [weak self] in self?.viewModel.fetch() }
        return view
    }()

    @IBSegueAction func showDetail(_ coder: NSCoder) -> DetailViewController? {
        let controller = DetailViewController(coder: coder)
        if let row = collectionView.indexPathsForSelectedItems?.first?.row {
            // 下一頁的 ViewModel 在這裡注入；DetailVC 自己不知道 Astro 哪來
            controller?.viewModel = AstroDetailViewModel(astro: viewModel.astro(at: row))
        }
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // App 再次冷啟動時若 server 帶 ETag/Last-Modified 可走 304，免再下載
        URLCache.shared = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: nil
        )

        applyAppearance()
        configureFlowLayout()
        bindViewModel()
        configureRefreshControl()

        viewModel.fetch()
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.configureFlowLayout()
        })
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.backgroundView = stateView
    }

    @objc private func refresh() {
        viewModel.fetch()
    }

    private func render(_ state: AstroListViewModel.State) {
        collectionView.refreshControl?.endRefreshing()
        switch state {
        case .idle:
            stateView.isHidden = true
        case .loading:
            if viewModel.numberOfItems == 0 {
                stateView.showLoading()
            }
        case .loaded:
            stateView.isHidden = true
            collectionView.reloadData()
        case .empty:
            collectionView.reloadData()
            stateView.showEmpty()
        case .failed(let message):
            stateView.showError(message)
        }
    }

    // MARK: - Appearance

    private func applyAppearance() {
        collectionView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.04, alpha: 1)
                : UIColor(white: 0.96, alpha: 1)
        }
        collectionView.alwaysBounceVertical = true

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

        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.estimatedItemSize = .zero
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: sideInset,
                                               left: sideInset,
                                               bottom: sideInset,
                                               right: sideInset)
        flowLayout.invalidateLayout()
    }

    // MARK: - DataSource

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

}

private final class CollectionStateView: UIView {
    var onRetry: (() -> Void)?

    private let indicator = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [indicator, titleLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        retryButton.setTitle("重試", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func showLoading() {
        isHidden = false
        titleLabel.text = "正在載入每日天文圖"
        messageLabel.text = nil
        retryButton.isHidden = true
        indicator.startAnimating()
        accessibilityLabel = titleLabel.text
    }

    func showEmpty() {
        show(title: "目前沒有天文圖", message: "請稍後再重新整理。", canRetry: true)
    }

    func showError(_ message: String) {
        show(title: "載入失敗", message: message, canRetry: true)
    }

    private func show(title: String, message: String, canRetry: Bool) {
        isHidden = false
        indicator.stopAnimating()
        titleLabel.text = title
        messageLabel.text = message
        retryButton.isHidden = !canRetry
        UIAccessibility.post(notification: .announcement, argument: "\(title)，\(message)")
    }

    @objc private func retry() { onRetry?() }
}
