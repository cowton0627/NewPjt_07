//
//  AstroCollectionViewController.swift
//  NewPjt_07
//
//  縮圖牆。VC 只持有 ViewModel，不再持有 [Astro] 或直接打 API。
//

import UIKit

class AstroCollectionViewController: UICollectionViewController {

    private let viewModel = AstroListViewModel()

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
        viewModel.onAstrosUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
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

    // MARK: - Error UI

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "載入失敗", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
