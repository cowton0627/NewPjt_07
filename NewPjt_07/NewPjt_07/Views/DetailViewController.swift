//
//  DetailViewController.swift
//  NewPjt_07
//
//  詳情頁 VC。由上一頁透過 IBSegueAction 注入 viewModel。
//  storyboard 寫死 rowHeight=651.5 且 desLabel 沒有 bottom→contentView 約束，
//  改用 heightForRowAt 依描述文字量動態算高，tableView 才能捲動長描述。
//

import UIKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var viewModel: AstroDetailViewModel!

    @IBOutlet weak var detailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self
        detailTableView.separatorStyle = .none
        detailTableView.showsVerticalScrollIndicator = false
        detailTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        navigationItem.largeTitleDisplayMode = .never
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // storyboard 上半部固定區塊（date + image + title + cpy + 各 spacing）約 342pt
        let headerHeight: CGFloat = 342
        let bottomPadding: CGFloat = 24
        // desLabel 左右各 DetailViewCell.horizontalInset，描述寬度要扣除
        let descWidth = tableView.bounds.width - DetailViewCell.horizontalInset * 2
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
